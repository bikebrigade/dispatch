defmodule BikeBrigadeWeb.CampaignController do
  use BikeBrigadeWeb, :controller

  alias BikeBrigade.Delivery
  alias NimbleCSV.RFC4180, as: CSV

  alias BikeBrigadeWeb.CampaignHelpers

  def download_assignments(conn, %{"id" => id}) do
    campaign = Delivery.get_campaign(id)
    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    tasks = tasks |> Enum.sort_by(&(&1.assigned_rider && &1.assigned_rider.name))

    headers = [
      "#",
      "status",
      "delivery notes",
      "rider",
      "rider email",
      "rider phone",
      "dropoff_name",
      "dropoff address",
      "dropoff phone",
      "box size",
      "rider notes"
    ]

    rows =
      for {task, i} <- Enum.with_index(tasks, 1) do
        {rider_name, rider_email, rider_phone} =
          if task.assigned_rider do
            {task.assigned_rider.name, task.assigned_rider.email, task.assigned_rider.phone}
          else
            {"", "", ""}
          end

        [
          i,
          task.delivery_status,
          task.delivery_status_notes,
          rider_name,
          rider_email,
          rider_phone,
          task.dropoff_name,
          "#{task.dropoff_address} #{task.dropoff_address2} #{task.dropoff_city} #{task.dropoff_postal}",
          task.dropoff_phone,
          CampaignHelpers.request_type(task),
          task.rider_notes
        ]
      end

    # TODO: use streams?

    file =
      [headers | rows]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()

    conn
    |> put_status(:ok)
    |> send_download({:binary, file},
      filename:
        "#{CampaignHelpers.campaign_date(campaign)}_#{CampaignHelpers.name(campaign)}_assignments.csv"
    )
  end

  def download_results(conn, %{"id" => id}) do
    campaign = Delivery.get_campaign(id)

    {_riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    tasks = tasks |> Enum.sort_by(& &1.delivery_status)

    headers = [
      "status",
      "delivery notes",
      "dropoff_name",
      "dropoff address",
      "partner organization"
    ]

    rows =
      for task <- tasks do
        [
          task.delivery_status,
          task.delivery_status_notes,
          task.dropoff_name,
          "#{task.dropoff_address} #{task.dropoff_address2} #{task.dropoff_city} #{task.dropoff_postal}",
          task.organization_partner
        ]
      end

    # TODO: use streams?

    file =
      [headers | rows]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()

    conn
    |> put_status(:ok)
    |> send_download({:binary, file},
      filename: "#{CampaignHelpers.campaign_date(campaign)}_#{CampaignHelpers.name(campaign)}_results.csv"
    )
  end
end
