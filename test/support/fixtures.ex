defmodule BikeBrigade.Fixtures do
  alias BikeBrigade.{Accounts, Delivery, Riders, Messaging, Messaging, Repo}
  alias BikeBrigade.Repo.Seeds.Toronto

  alias BikeBrigade.Repo.Seeds.Toronto

  def fixture(name) when is_atom(name), do: fixture(name, %{})

  def fixture(:user, attrs) do
    {:ok, user} =
      %{
        name: fake_name(),
        email: Faker.Internet.email(),
        phone: fake_phone()
      }
      |> Map.merge(attrs)
      |> Accounts.create_user_as_admin()

    user
  end

  def fixture(:program, attrs) do
    {:ok, program} =
      %{
        name: Faker.Superhero.name(),
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
    # Create a program if we don't have one
    attrs =
      attrs
      |> Map.put_new_lazy(:program_id, fn ->
        fixture(:program).id
      end)

    {:ok, campaign} =
      %{
        delivery_start: DateTime.utc_now(),
        delivery_end: DateTime.utc_now() |> DateTime.add(60, :second),
        location: Toronto.random_location()
      }
      |> Map.merge(attrs)
      |> Delivery.create_campaign()

    campaign
    |> Repo.preload(program: [:items])
  end

  def fixture(:campaign_with_riders, _attrs) do
    campaign = fixture(:campaign)

    riders = for _i <- 1..7 do
      fixture(:rider)
    end
    Enum.each(riders, fn rider ->
      Delivery.create_campaign_rider(%{
            campaign_id: campaign.id,
            rider_id: rider.id
            })
    end)
    {campaign, riders}
  end

  def fixture(:rider, attrs) do
    location = Toronto.random_location()
    {:ok, rider} =
      %{
        name: fake_name(),
        email: Faker.Internet.email(),
        phone: fake_phone(),
        pronouns: Enum.random(~w(He/Him She/Her They/Them)),
        country: location.country,
        location: location,
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

  def fixture(:task, attrs) do
    {campaign, attrs} = Map.pop_lazy(attrs, :campaign, fn -> fixture(:campaign) end)
    {rider, attrs} = Map.pop(attrs, :rider)

    if rider do
      # assign rider to campaign

      Delivery.create_campaign_rider(%{
        campaign_id: campaign.id,
        rider_id: rider.id
      })
    end

    rider_id = if rider, do: rider.id

    # Create a task (possibly assigned to rider)
    {:ok, task} =
      Delivery.create_task_for_campaign(
        campaign,
        %{
          dropoff_name: Faker.Person.first_name(),
          dropoff_location: Toronto.random_location(),
          task_items: [%{item_id: hd(campaign.program.items).id, count: 1}],
          assigned_rider_id: rider_id
        }
        |> Map.merge(attrs)
      )

    task
  end

  def fixture(:opportunity, attrs) do
    {:ok, opportunity} =
      %{
        delivery_start: DateTime.utc_now(),
        delivery_end: DateTime.utc_now() |> DateTime.add(60, :second),
        signup_link: Faker.Internet.url(),
        location: Toronto.random_location()
      }
      |> Map.merge(attrs)
      |> Delivery.create_opportunity()

    opportunity
  end

  def fixture(:location, _attrs) do
    Toronto.random_location()
  end

  def fixture(:sms_message_from_rider, rider),
    do: fixture(:sms_message_from_rider, rider, %{})

  def fixture(:sms_message_to_rider, rider),
    do: fixture(:sms_message_to_rider, rider, %{})

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

  def fixture(:sms_message_from_rider, rider, attrs) do
    fixture(:sms_message, Map.merge(attrs, %{rider_id: rider.id, from: rider.phone}))
  end

  def fixture(:sms_message_to_rider, rider, attrs) do
    fixture(:sms_message, Map.merge(attrs, %{rider_id: rider.id, to: rider.phone}))
  end

  defp fake_name() do
    # Faker has names like O'Connel, and the apostrophe gets translated to &#39; in HTML output
    # This is annoying in tests so we'll just filter out the apostrophe.
    "#{Faker.Person.first_name()} #{Faker.Person.last_name()}"
    |> String.replace(~r/[^a-zA-Z\s]/, "")
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
