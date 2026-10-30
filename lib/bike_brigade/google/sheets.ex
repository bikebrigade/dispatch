defmodule BikeBrigade.Google.Sheets do
  def get_values(spreadsheet_url) do
    with {:ok, id, gid} <- parse_url(spreadsheet_url),
         {:ok, req} <- BikeBrigade.Google.request(),
         {:ok, %Req.Response{status: 200, body: %{"valueRanges" => [value_range | _]}}} <-
           Req.post(req,
             url:
               "https://sheets.googleapis.com/v4/spreadsheets/#{id}/values:batchGetByDataFilter",
             json: build_body(gid)
           ) do
      {:ok, value_range["valueRange"]["values"]}
    else
      {:ok, %Req.Response{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, err} -> {:error, err}
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
