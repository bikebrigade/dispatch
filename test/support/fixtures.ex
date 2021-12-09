defmodule BikeBrigade.Fixtures do
  alias BikeBrigade.{Accounts, Delivery, Riders, Messaging, Messaging, Repo}

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
        pickup_address: "926 College St",
        pickup_address2: nil,
        pickup_city: "Toronto",
        pickup_country: "Canada",
        pickup_location: %Geo.Point{
          coordinates: {-79.4258633, 43.6539952},
          properties: %{},
          srid: 4326
        },
        pickup_postal: "M6H 1A4",
        pickup_province: "Ontario",
        pickup_window: "3-4pm"
      }
      |> Map.merge(attrs)
      |> Delivery.create_campaign()

    campaign
  end

  def fixture(:rider, attrs) do
    {:ok, rider} =
      %{
        name: fake_name(),
        email: Faker.Internet.email(),
        phone: fake_phone(),
        address: "926 College St",
        address2: nil,
        city: "Toronto",
        country: "Canada",
        location: %Geo.Point{
          coordinates: {-79.4258633, 43.6539952},
          properties: %{},
          srid: 4326
        },
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

  def fixture(:opportunity, attrs) do
    {:ok, opportunity} =
      %{
        delivery_start: DateTime.utc_now(),
        delivery_end: DateTime.utc_now() |> DateTime.add(60, :second),
        signup_link: Faker.Internet.url()
      }
      |> Map.merge(attrs)
      |> Delivery.create_opportunity()

      opportunity
  end

  def fixture(:location, _attrs) do
    BikeBrigade.Location.new(%{
      lat: random_float(43.633528, 43.772528),
      lon: random_float(-79.548444, -79.232583),
      city: "Toronto",
      postal: "H0H 0H0",
      province: "Ontario",
      country: "Canada"
    })
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

  defp random_float(a, b) do
    a + :rand.uniform() * (b - a)
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
