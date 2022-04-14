defmodule BikeBrigadeWeb.DeliveryExpiredError do
  defexception message: "delivery is expired", plug_status: 403
end
