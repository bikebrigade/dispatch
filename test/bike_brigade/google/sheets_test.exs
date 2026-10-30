defmodule BikeBrigade.Google.SheetsTest do
  use ExUnit.Case, async: true

  alias BikeBrigade.Google.Sheets

  @url "https://docs.google.com/spreadsheets/d/sheet-id/edit#gid=42"

  describe "get_values/1" do
    test "fetches the values for the sheet in the URL" do
      Req.Test.stub(BikeBrigade.Google, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        send(self(), {:request, conn, body})

        Req.Test.json(conn, %{
          "spreadsheetId" => "sheet-id",
          "valueRanges" => [
            %{"valueRange" => %{"values" => [["name", "phone"], ["Ada", "555-1234"]]}}
          ]
        })
      end)

      assert {:ok, [["name", "phone"], ["Ada", "555-1234"]]} = Sheets.get_values(@url)

      assert_received {:request, conn, body}
      assert conn.method == "POST"
      assert conn.host == "sheets.googleapis.com"
      assert conn.request_path == "/v4/spreadsheets/sheet-id/values:batchGetByDataFilter"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-token"]
      assert Jason.decode!(body) == %{"dataFilters" => [%{"gridRange" => %{"sheetId" => 42}}]}
    end

    test "returns the status and body on an HTTP error" do
      Req.Test.stub(BikeBrigade.Google, fn conn ->
        conn
        |> Plug.Conn.put_status(404)
        |> Req.Test.json(%{"error" => %{"message" => "not found"}})
      end)

      assert {:error, {:http_error, 404, %{"error" => %{"message" => "not found"}}}} =
               Sheets.get_values(@url)
    end

    test "returns an error for a non-spreadsheet URL without making a request" do
      Req.Test.stub(BikeBrigade.Google, fn _conn -> flunk("should not make a request") end)

      assert {:error, "couldn't parse spreadsheet url"} =
               Sheets.get_values("https://example.com/not-a-sheet")
    end
  end

  describe "parse_url/1" do
    test "extracts the spreadsheet and sheet ids" do
      assert {:ok, "sheet-id", 42} = Sheets.parse_url(@url)
    end

    test "defaults to the first sheet" do
      assert {:ok, "sheet-id", 0} =
               Sheets.parse_url("https://docs.google.com/spreadsheets/d/sheet-id/edit")
    end
  end
end
