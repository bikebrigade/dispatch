defmodule BikeBrigade.Google.Sheets do
  alias GoogleApi.Sheets.V4.Connection
  alias GoogleApi.Sheets.V4.Api.Spreadsheets

  def get_values(spreadsheet_url) do
    with {:ok, token} <- Goth.fetch(BikeBrigade.Google),
         conn <- Connection.new(token.token),
         {:ok, id, gid} <- parse_url(spreadsheet_url),
         {:ok, response} <-
           Spreadsheets.sheets_spreadsheets_values_batch_get_by_data_filter(
             conn,
             id,
             body: build_body(gid)
           ) do
      {:ok, hd(response.valueRanges).valueRange.values}
    else
      {:error, err} -> {:error, err}
      _ -> {:error, "unable to fetch sheet"}
    end
  end

  defp build_body(gid) do
    %{dataFilters: [%{gridRange: %{sheetId: gid}}]}
  end

  def parse_url(url) do
    id_regex =
      ~r/^https:\/\/docs.google.com\/spreadsheets\/d\/(?<spreadsheet_id>[^\/]*)\/.*?(#gid=(?<sheet_id>\d+))?$/

    if captures = Regex.named_captures(id_regex, url) do
      case Integer.parse(captures["sheet_id"]) do
        {sheet_id, ""} -> {:ok, captures["spreadsheet_id"], sheet_id}
        _ -> {:ok, captures["spreadsheet_id"], 0}
      end
    else
      {:error, "couldn't parse spreadsheet url"}
    end
  end
end
