defmodule BikeBrigadeWeb.PrintableLive.Helpers do
  alias BikeBrigade.Delivery

  def new_rider?(assigned_rider) do
    campaign_count = Delivery.campaigns_per_rider(assigned_rider)

    if campaign_count <= 1 do
      true
    else
      false
    end
  end
end
