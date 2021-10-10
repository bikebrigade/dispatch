defmodule BikeBrigadeWeb.ExportStatsController do
  use BikeBrigadeWeb, :controller

  alias BikeBrigade.Stats
  alias NimbleCSV.RFC4180, as: CSV

  def leaderboard(conn, params) do
    stats = fetch_stats(params)

    headers = ~W(Rider Email  Phone Campaigns Deliveries Distance)

    rows =  for {rider, campaigns, deliveries, distance} <- stats do
      [rider.name, rider.email, rider.phone, campaigns, deliveries, distance]
    end

    # TODO: use streams?

    file =
      [headers | rows]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()

    conn
    |> put_status(:ok)
    |> send_download({:binary, file}, filename: "rider_stats.csv")
  end

  defp fetch_stats(%{"sort_by" => sort_by, "sort_order" => sort_order, "start_date" => start_date, "end_date" => end_date}) do
    Stats.rider_leaderboard(String.to_atom(sort_by), String.to_atom(sort_order), Date.from_iso8601!(start_date), Date.from_iso8601!(end_date))
  end

  defp fetch_stats(%{"sort_by" => sort_by, "sort_order" => sort_order}) do
    Stats.rider_leaderboard(String.to_atom(sort_by), String.to_atom(sort_order))
  end


end
