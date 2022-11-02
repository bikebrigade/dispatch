defmodule BikeBrigadeWeb.EmbedTestController do
  use BikeBrigadeWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html", layout: false)
  end
end
