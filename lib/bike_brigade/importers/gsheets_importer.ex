defmodule BikeBrigade.Importers.GSheetsImporter do
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
      boxes = String.to_integer(boxes)
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

    Delivery.update_campaign(campaign, %{tasks: tasks})
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
        partner,
        request_type | _
      ] = row

      campaign = campaign |> Repo.preload(program: [:items])

      pickup_name = "Max Veytsman"
      pickup_email = "info@bikebrigade.ca"
      pickup_phone = "6478690658"

      notes =
        if buzzer != "" do
          "(#{buzzer}) #{notes}"
        else
          notes
        end

      phone = trim_phone(phone)

      %{
        organization_name: "Foodshare",
        contact_email: pickup_email,
        contact_name: pickup_name,
        contact_phone: pickup_phone,
        delivery_window: "5-7",
        size: 4,
        submitted_on: NaiveDateTime.local_now(),
        dropoff_name: name,
        dropoff_phone: phone,
        dropoff_address: street,
        dropoff_postal: postal,
        rider_notes: notes,
        delivery_status: :pending,
        organization_partner: partner
      }
      |> Map.merge(
        case process_request_type(request_type, campaign.program.items) do
          {count, item_id} -> %{task_items: [%{count: count, item_id: item_id}]}
          request_type when is_binary(request_type) -> %{request_type: request_type}
        end
      )
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
        partner,
        regular,
        vegetarian | _
      ] = row

      campaign = campaign |> Repo.preload(program: [:items])

      pickup_name = "Max Veytsman"
      pickup_email = "info@bikebrigade.ca"
      pickup_phone = "6478690658"

      notes =
        if buzzer != "" do
          "(#{buzzer}) #{notes}"
        else
          notes
        end

      phone = trim_phone(phone)

      task_items = for {count, id} <- [
            process_request_type("#{regular} regular", campaign.program.items),
            process_request_type("#{vegetarian} vegetarian", campaign.program.items)
          ],
          count > 0 do
            %{count: count, item_id: id}
      end
      %{
        organization_name: "Foodshare",
        contact_email: pickup_email,
        contact_name: pickup_name,
        contact_phone: pickup_phone,
        delivery_window: "5-7",
        size: 4,
        submitted_on: NaiveDateTime.local_now(),
        dropoff_name: name,
        dropoff_phone: phone,
        dropoff_address: street,
        dropoff_postal: postal,
        rider_notes: notes,
        delivery_status: :pending,
        organization_partner: partner,
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
