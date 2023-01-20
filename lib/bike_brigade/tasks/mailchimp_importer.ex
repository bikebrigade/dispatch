defmodule BikeBrigade.Tasks.MailchimpImporter do
  import Ecto.Query, warn: false
  import BikeBrigade.Utils, only: [get_config: 1, with_default: 2]
  alias BikeBrigade.Repo
  alias BikeBrigade.Locations.Location
  alias BikeBrigade.Tasks.Importer
  alias BikeBrigade.Riders
  alias BikeBrigade.Messaging.Slack
  alias BikeBrigade.MailchimpApi

  use Phoenix.VerifiedRoutes, endpoint: BikeBrigadeWeb.Endpoint, router: BikeBrigadeWeb.Router

  @importer_name "mailchimp"

  # Lets us update values in maps stored as jsonb without losing keys we dont care about
  @update_data_map from(i in Importer,
                     update: [set: [data: fragment("? || excluded.data", i.data)]]
                   )

  def sync_riders() do
    Repo.transaction(
      fn ->
        last_synced =
          Repo.one(
            from i in Importer,
              where: i.name == ^@importer_name,
              lock: "FOR UPDATE SKIP LOCKED",
              select: fragment("? ->> 'last_synced'", i.data)
          )

        list_id = get_config(:list_id)

        with {:ok, members} <- MailchimpApi.get_list(list_id, last_synced) do
          for member <- members do
            case parse_mailchimp_attrs(member) do
              {:ok, rider_attrs} ->
                create_or_update(rider_attrs)

              {:error, {:update_location, rider_attrs}} ->
                {:ok, rider} =
                  rider_attrs
                  |> put_default_location()
                  |> create_or_update()

                notify_location_error(rider)
                tag_invalid_location(rider)

              {:error, error} ->
                notify_import_error(member, error)
            end
          end

          Repo.insert(%Importer{name: @importer_name, data: %{last_synced: DateTime.utc_now()}},
            returning: true,
            on_conflict: @update_data_map,
            conflict_target: :name
          )
        end
      end,
      timeout: :infinity
    )
  end

  def create_or_update(rider_attrs) do
    case find_existing_rider(rider_attrs) do
      {:phone, rider} ->
        # the rider exists, update
        # TODO: when we are source of truth for these don't need to update all the fields?
        Riders.update_rider(rider, rider_attrs)

      {:email, rider} ->
        # the rider exists, but mailchimp has the wrong phone
        # Assume ours is correct!
        rider_attrs = Map.delete(rider_attrs, :phone)
        Riders.update_rider(rider, rider_attrs)

      nil ->
        Riders.create_rider(rider_attrs)
    end
  end

  @default_location %{
    address: "1 Front Street West",
    city: "Toronto",
    coords: %Geo.Point{
      coordinates: {-79.37761739999999, 43.6459904},
      srid: nil,
      properties: %{}
    },
    country: "Canada",
    postal: "M5J 2X5",
    province: "Ontario"
  }

  def put_default_location(rider_attrs) do
    Map.put(rider_attrs, :location, @default_location)
  end

  def tag_invalid_location(rider) do
    # TODO make this an idempotent Riders.add_tag
    rider =
      rider
      |> Repo.preload(:tags)

    tags = Enum.map(rider.tags, & &1.name) ++ ["invalid_location"]

    Riders.update_rider_with_tags(rider, %{}, tags)
  end

  def notify_location_error(rider) do
    error_message = """
      We had trouble with the address for #{rider.name}. Please edit manually: #{~p"/riders/#{rider}/edit"}, and don't forget to remove the `invalid_location` tag!
    """

    Task.start(Slack.Operations, :post_message!, [error_message])
  end

  def notify_import_error(member, error) do
    error_message =
      "An error ocurred when importing #{member.email_address} #{Kernel.inspect(error)}"

    Task.start(Slack.Operations, :post_message!, [error_message])
  end

  def parse_mailchimp_attrs(member) do
    phone = with_default(member.merge_fields[:PHONEYUI_], member.merge_fields[:PHONE])

    with {:ok, phone} <- BikeBrigade.EctoPhoneNumber.Canadian.cast(phone) do
      email = member.email_address
      name = String.trim("#{member.merge_fields[:FNAME]} #{member.merge_fields[:LNAME]}")
      pronouns = member.merge_fields[:TEXT7C393]
      address = member.merge_fields[:TEXTYUI_3]
      _address2 = member.merge_fields[:TEXT2]
      postal = member.merge_fields[:TEXT5]
      city = with_default(member.merge_fields[:TEXT3], "Toronto")
      province = with_default(member.merge_fields[:SELECTYUI], "Ontario")
      country = with_default(member.merge_fields[:TEXT3], "Canada")

      max_distance = translate_max_distance(member.merge_fields[:RADIO16])
      capacity = translate_capacity(member.merge_fields[:RADIOYUI_])

      raw_location = %{
        address: address,
        postal: postal,
        city: city,
        province: province,
        country: country
      }

      rider_attrs = %{
        mailchimp_id: member.id,
        mailchimp_status: member.status,
        phone: phone,
        email: email,
        name: name,
        pronouns: pronouns,
        signed_up_on: member.timestamp_opt,
        max_distance: max_distance,
        capacity: capacity,
        raw_location: raw_location
      }

      case geolocate_raw_location(raw_location) do
        {:ok, location} ->
          {:ok, Map.put(rider_attrs, :location, Map.from_struct(location))}

        {:error, _} ->
          {:error, {:update_location, rider_attrs}}
      end
    else
      {:error, err} ->
        {:error, err}
    end
  end

  def find_existing_rider(rider_attrs) do
    %{phone: phone, email: email} = rider_attrs

    cond do
      rider = Riders.get_rider_by_phone(phone) -> {:phone, rider}
      rider = Riders.get_rider_by_email(email) -> {:email, rider}
      true -> nil
    end
  end

  def geolocate_raw_location(location) do
    Location.geocoding_changeset(%Location{}, %{
      address: location.address,
      postal: location.postal,
      city: location.city,
      province: location.province,
      country: location.country
    })
    # TODO: this should be a method on the location struct to validate
    |> Ecto.Changeset.apply_action(:save)
  end

  defp translate_max_distance(max_distance) do
    case max_distance do
      "I can ride anywhere, no matter how far! (in the City of Toronto)" -> 25
      "Less than 5km from my postal code" -> 5
      "5-10km from my address" -> 10
      "10-15km from my address" -> 15
      "15km+ from my address" -> 20
      _ -> 10
    end
  end

  defp translate_capacity(capacity) do
    case capacity do
      ~r/1 personal backpack \+ cargo trailer/ ->
        :large

      ~r/1 personal backpack \+ saddlebags/ ->
        :medium

      ~r/1 personal backpack/ ->
        :small

      _ ->
        :medium
    end
  end
end
