defmodule BikeBrigade.GSheetsImporter do
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Riders
  alias BikeBrigade.Repo

  alias BikeBrigade.Google.Sheets

  def import_riders_from_spreadsheet(
        %Campaign{rider_spreadsheet_layout: spreadsheet_layout} = campaign,
        spreadsheet_url
      ) do
    campaign = campaign |> Repo.preload(:riders)

    {:ok, row_data} = Sheets.get_values(spreadsheet_url)

    fun =
      case spreadsheet_layout do
        :foodshare -> &process_rider_row_foodshare/2
        :non_foodshare -> &process_rider_row_map/2
        :map -> &process_rider_row_map/2
        _ -> &process_rider_row_foodshare/2
      end

    for row <- Enum.drop(row_data, 1) do
      fun.(campaign, row)
    end
    |> Enum.filter(&(&1 != nil))
  end

  def process_rider_row_foodshare(campaign, row) do
    [
      _time,
      email,
      _volunteered,
      _covid1,
      _covid2,
      _covid3,
      _covid4,
      covid_app,
      _name,
      phone,
      boxes,
      _trips,
      time_slot,
      entering | rst
    ] = row

    if covid_app == "Yes, I agree" do
      notes = List.first(rst) || ""

      boxes =
        case Integer.parse(boxes) do
          {boxes, _} -> boxes
          _ -> 0
        end

      enter_building = entering == "Yes"

      IO.puts("#{email}, #{entering}, #{enter_building}")

      if boxes > 0 do
        rider = Riders.get_rider_by_phone(phone) || Riders.get_rider_by_email!(email)

        Delivery.create_campaign_rider(%{
          campaign_id: campaign.id,
          rider_id: rider.id,
          rider_capacity: boxes,
          pickup_window: time_slot,
          enter_building: enter_building,
          notes: notes
        })
      end
    end
  end

  def process_rider_row_map(campaign, row) do
    [
      _time,
      email,
      _volunteered,
      _name,
      phone,
      boxes,
      entering
      | rst
    ] = row

    notes = List.first(rst) || ""
    boxes = String.to_integer(boxes)
    enter_building = entering == "Yes"

    IO.puts("#{email}, #{entering}, #{enter_building}")

    if boxes > 0 do
      rider = Riders.get_rider_by_phone(phone) || Riders.get_rider_by_email!(email)

      Delivery.create_campaign_rider(%{
        campaign_id: campaign.id,
        rider_id: rider.id,
        rider_capacity: boxes,
        enter_building: enter_building,
        notes: notes
      })
    end
  end

  def import_tasks_from_spreadsheet(
        %Campaign{} = campaign,
        spreadsheet_url
      ) do
    campaign = campaign |> Repo.preload([:tasks, :program])
    {:ok, row_data} = Sheets.get_values(spreadsheet_url)

    tasks =
      for row <- Enum.drop(row_data, 1) do
        case campaign.program.spreadsheet_layout do
          :map -> process_delivery_row_map(campaign, row)
          _ -> process_delivery_row(campaign, row)
        end
      end
      |> Enum.filter(&(&1 != nil))

    Delivery.update_campaign(campaign, %{tasks: tasks}, geocode_tasks: true)
  end

  def process_delivery_row(campaign, row) do
    if Enum.count(row) >= 8 do
      [
        name,
        street,
        postal,
        phone,
        notes,
        buzzer,
        partner_tracking_id,
        request_type | _
      ] = row

      campaign = campaign |> Repo.preload(program: [:items])

      notes =
        if buzzer != "" do
          "(#{buzzer}) #{notes}"
        else
          notes
        end

      phone = trim_phone(phone)

      {count, item_id} = process_request_type(request_type, campaign.program.items)

      %{
        delivery_window: "5-7",
        submitted_on: NaiveDateTime.local_now(),
        dropoff_name: name,
        dropoff_phone: phone,
        dropoff_location: %{address: street, postal: postal},
        rider_notes: notes,
        delivery_status: :pending,
        partner_tracking_id: partner_tracking_id,
        task_items: [%{count: count, item_id: item_id}]
      }
    end
  end

  def process_delivery_row_map(campaign, row) do
    if Enum.count(row) >= 9 && hd(row) != "" do
      [
        name,
        street,
        postal,
        phone,
        notes,
        buzzer,
        partner_tracking_id,
        regular,
        vegetarian | _
      ] = row

      campaign = campaign |> Repo.preload(program: [:items])

      notes =
        if buzzer != "" do
          "(#{buzzer}) #{notes}"
        else
          notes
        end

      phone = trim_phone(phone)

      task_items =
        for {count, id} <- [
              process_request_type("#{regular} regular", campaign.program.items),
              process_request_type("#{vegetarian} vegetarian", campaign.program.items)
            ],
            count > 0 do
          %{count: count, item_id: id}
        end

      %{
        delivery_window: "5-7",
        submitted_on: NaiveDateTime.local_now(),
        dropoff_name: name,
        dropoff_phone: phone,
        dropoff_location: %{address: street, postal: postal},
        rider_notes: notes,
        delivery_status: :pending,
        partner_tracking_id: partner_tracking_id,
        task_items: task_items
      }
    end
  end

  defp trim_phone(nil) do
    nil
  end

  defp trim_phone(phone) when is_binary(phone) do
    case String.trim(phone) do
      "" -> nil
      phone -> phone
    end
  end

  # Campaign has no items do nothing
  defp process_request_type(request_type, []) do
    request_type
  end

  # TODO multiple kinds of items available
  defp process_request_type(request_type, items) do
    {count, name} =
      case Integer.parse(request_type) do
        {count, name} -> {count, name}
        :error -> {1, request_type}
      end

    item =
      case items do
        [item] -> item
        items -> hd(Enum.sort_by(items, &String.jaro_distance(name, &1.name), :desc))
      end

    {count, item.id}
  end
end
