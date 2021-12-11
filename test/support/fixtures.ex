defmodule BikeBrigade.Fixtures do
  alias BikeBrigade.{Location, Accounts, Delivery, Riders, Messaging, Messaging, Repo}

  def fixture(name), do: fixture(name, %{})

  def fixture(:user, attrs) do
    {:ok, user} =
      %{
        name: fake_name(),
        email: Faker.Internet.email(),
        phone: fake_phone()
      }
      |> Map.merge(attrs)
      |> Accounts.create_user()

    user
  end

  def fixture(:program, attrs) do
    {:ok, program} =
      %{
        name: "program",
        start_date: DateTime.utc_now()
      }
      |> Map.merge(attrs)
      |> Delivery.create_program()

    {:ok, _item} =
      fake_item()
      |> Map.merge(%{program_id: program.id})
      |> Delivery.create_item()

    program
    |> Repo.preload(:items)
  end

  def fixture(:campaign, attrs) do
    {:ok, campaign} =
      %{
        delivery_start: DateTime.utc_now(),
        delivery_end: DateTime.utc_now() |> DateTime.add(60, :second),
        name: "campaign",
        location: %{
          address: "926 College St",
          postal: "M6H 1A1",
          city: "Toronto",
          province: "Canada",
          country: "Canada",
          coords:
            Jason.encode!(%Geo.Point{
              coordinates: {-79.4258633, 43.6539952},
              properties: %{},
              srid: 4326
            })
        }
      }
      |> Map.merge(attrs)
      |> Delivery.create_campaign()

    campaign
  end

  def fixture(:rider, attrs) do
    location = %Geo.Point{
      coordinates: {-79.4258633, 43.6539952},
      properties: %{},
      srid: 4326
    }

    {:ok, rider} =
      %{
        name: fake_name(),
        email: Faker.Internet.email(),
        phone: fake_phone(),
        address: "926 College St",
        address2: nil,
        city: "Toronto",
        country: "Canada",
        location: location,
        location_struct: %{coords: location},
        postal: "M6H 1A4",
        province: "Ontario",
        availability: %{
          "fri" => "all_day",
          "mon" => "all_day",
          "sat" => "all_day",
          "sun" => "all_day",
          "thu" => "all_day",
          "tue" => "all_day",
          "wed" => "all_day"
        },
        capacity: :medium,
        max_distance: 10
      }
      |> Map.merge(attrs)
      |> Riders.create_rider()

    rider
  end

  def fixture(:location, _attrs) do
    %Location{
      address: "926 College Street",
      neighborhood: "Palmerston-Little Italy",
      city: "Toronto",
      postal: "M6H 1A1",
      province: "Ontario",
      country: "Canada"
    }
    |> Location.set_coords(43.6539952, -79.4258633)
  end

  def fixture(:sms_message, attrs) do
    defaults = %{
      incoming: true,
      body: Faker.Lorem.Shakespeare.king_richard_iii(),
      from: fake_phone(),
      sent_at: DateTime.utc_now(),
      to: fake_phone(),
      twilio_sid: "twilio_sid",
      twilio_status: "twilio_status"
    }

    {:ok, sms} =
      defaults
      |> Map.merge(attrs)
      |> Messaging.create_sms_message()

    Messaging.get_sms_message!(sms.id)
    |> Repo.preload(:rider)
  end

  def fixture(:sms_media_item, attrs) do
    defaults = %{
      url: Faker.Internet.url(),
      content_type: "image/jpeg"
    }

    Map.merge(defaults, attrs)
  end

  defp fake_name() do
    "#{Faker.Person.first_name()} #{Faker.Person.last_name()}"
  end

  # Faker's phone doesn't always pass canadian validation
  defp fake_phone() do
    "647-#{Enum.random(200..999)}-#{Enum.random(1000..9999)}"
  end

  defp fake_item() do
    %{
      name: "Foodshare Box",
      plural: "Foodshare Boxes",
      description: "a box",
      category: "Foodshare Box"
    }
  end
end
