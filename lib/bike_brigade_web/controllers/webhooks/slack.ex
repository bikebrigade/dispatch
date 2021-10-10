defmodule BikeBrigadeWeb.Webhooks.Slack do
  use BikeBrigadeWeb, :controller

  def webhook(conn, _) do
    send_resp(conn, :ok, "")
  end
end
