defmodule BikeBrigade.Repo.Seeds.Seeder do
  alias BikeBrigade.{
    Accounts,
    Delivery,
    LocalizedDateTime,
    Riders,
    Utils
  }

  alias BikeBrigade.Repo.Seeds.Toronto

  def user() do
    {:ok, %Accounts.User{} = user} =
      Accounts.create_user_as_admin(%{
        name: "Dispatcher McGee",
        phone: "647-555-5555",
        email: "dispatcher@example.com"
      })

    user
  end

  def program() do
    {:ok, %Delivery.Program{} = program} =
      Delivery.create_program(%{
        name: Faker.Company.name(),
        start_date: LocalizedDateTime.now()
      })

    program
  end

  def campaign_for_program(program) do
    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    {:ok, %Delivery.Campaign{} = campaign} =
      Delivery.create_campaign(%{
        program_id: program.id,
        delivery_start: current_week |> start_of_day(),
        delivery_end: current_week |> Date.add(6) |> end_of_day(),
        location: Toronto.random_location()
      })

    campaign
  end

  def rider() do
    location = Toronto.random_location()

    {:ok, %Riders.Rider{} = rider} =
      Riders.create_rider(%{
        address: location.address,
        # TODO
        capacity: Utils.random_enum(Riders.Rider.CapacityEnum),
        email: Faker.Internet.email(),
        location: location,
        max_distance: 20,
        name: "#{Faker.Person.first_name()} #{Faker.Person.last_name()}",
        phone: "647-#{Enum.random(200..999)}-#{Enum.random(1000..9999)}",
        postal: location.postal,
        pronouns: Enum.random(~w(He/Him She/Her They/Them)),
        signed_up_on: LocalizedDateTime.now()
      })

    rider
  end

  def rider_for_campaign(campaign) do
    rider =
      Riders.list_riders()
      |> Enum.random()

    Delivery.create_campaign_rider(%{
      campaign_id: campaign.id,
      rider_id: rider.id
    })

    rider
  end

  def task_for_campaign(campaign) do
    item = Enum.random(Delivery.list_items(campaign.program_id))
    count = Enum.random(1..5)

    {:ok, %Delivery.Task{} = task} =
      campaign
      |> Delivery.create_task_for_campaign(%{
        dropoff_name: Faker.Person.first_name(),
        dropoff_location: Toronto.random_location(),
        task_items: [%{item_id: item.id, count: count}]
      })

    task
  end

  def item_for_program(program) do
    random_item_category =
      Delivery.Item
      |> Ecto.Enum.values(:category)
      |> Enum.random()

    {:ok, %Delivery.Item{} = item} =
      Delivery.create_item(%{
        program_id: program.id,
        name: Faker.Food.dish(),
        category: random_item_category
      })

    item
  end

  defp start_of_day(date), do: set_time(date, ~T[00:00:00])
  defp end_of_day(date), do: set_time(date, ~T[23:59:59])
  defp set_time(date, time), do: LocalizedDateTime.new!(date, time)
end
