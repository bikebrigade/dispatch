defmodule BikeBrigadeWeb.StatusController do
  use BikeBrigadeWeb, :controller

  def status(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok"})
  end

  def conn(conn, _params) do
    conn
    |> put_status(:ok)
    |> text(inspect(conn))
  end

end
