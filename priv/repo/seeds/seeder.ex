defmodule BikeBrigade.Repo.Seeds.Seeder do
  alias BikeBrigade.{
    Delivery,
    LocalizedDateTime,
    Riders
  }

  alias BikeBrigade.Repo.Seeds.Toronto

  def program() do
    {:ok, %Delivery.Program{}} =
      Delivery.create_program(%{
        name: Faker.Company.name(),
        start_date: LocalizedDateTime.now()
      })
  end

  def campaign() do
    current_week =
      LocalizedDateTime.today()
      |> Date.beginning_of_week()

    {:ok, campaign} =
      Delivery.create_campaign(%{
        # key :name not found in: %BikeBrigade.Delivery.Campaign{…}
        name: Faker.Company.name(),
        delivery_start: current_week |> start_of_day(),
        delivery_end: current_week |> Date.add(6) |> end_of_day(),
        location: Toronto.random_location()
      })

    campaign
  end

  def rider_for_campaign(campaign) do
    rider =
      Riders.list_riders()
      |> Enum.random()

    # validate_required([:campaign_id, :rider_id, :rider_capacity, :enter_building, :token])
    Delivery.create_campaign_rider(%{
      campaign_id: campaign.id,
      rider_id: rider.id
    })
  end

  defdelegate task_for_campaign(campaign), to: Delivery, as: :create_task_for_campaign

  def item_for_program(program) do
    random_item_category =
      Delivery.Item
      |> Ecto.Enum.values(:category)
      |> Enum.random()

    {:ok, _item} =
      Delivery.create_item(%{
        program_id: program.id,
        name: Faker.Food.dish(),
        category: random_item_category
      })
  end

  defp start_of_day(date), do: set_time(date, ~T[00:00:00])
  defp end_of_day(date), do: set_time(date, ~T[23:59:59])
  defp set_time(date, time), do: LocalizedDateTime.new!(date, time)
end
