defmodule BikeBrigadeWeb.DeliveryHelpers do
  alias BikeBrigade.Delivery.{Campaign, Task}
  alias BikeBrigade.Messaging

  alias BikeBrigade.GoogleMaps

  import BikeBrigade.Riders.Helpers, only: [first_name: 1]

  alias BikeBrigadeWeb.CampaignHelpers

  defdelegate campaign_name(campaign), to: CampaignHelpers, as: :name

  def sms_url(_campaign, _rider, %Task{dropoff_phone: nil}), do: nil
  def sms_url(_campaign, _rider, %Task{dropoff_phone: ""}), do: nil

  def sms_url(campaign, rider, task) do
    message =
      "Hi #{first_name(task)}, it's #{first_name(rider)} from the Bike Brigade delivering for #{campaign_name(campaign)}! I'll be arriving shortly with a delivery for you! Are you available to receive it?"

    {:sms, "#{task.dropoff_phone}?&body=#{URI.encode(message)}"}
  end

  def sms_done_url(campaign, rider) do
    message = "I'm done with this #{campaign_name(campaign)} delivery!"
    {:sms, "#{Messaging.inbound_number(rider)}?&body=#{URI.encode(message)}"}
  end

  def tel_url(%Task{dropoff_phone: nil}), do: nil
  def tel_url(%Task{dropoff_phone: ""}), do: nil

  def tel_url(%Task{dropoff_phone: dropoff_phone}) do
    {:tel, "#{dropoff_phone}"}
  end

  def embed_directions_url(assigns) do
    %{campaign: campaign, rider: rider} = assigns

    dropoff_locations = Enum.map(rider.assigned_tasks, & &1.dropoff_location)

    GoogleMaps.embed_directions_url(campaign.location, dropoff_locations)
  end

  def directions_url(assigns) do
    %{campaign: campaign, rider: rider} = assigns

    dropoff_locations = Enum.map(rider.assigned_tasks, & &1.dropoff_location)

    GoogleMaps.directions_url(campaign.location, dropoff_locations)
  end

  def open_map_url(%Task{dropoff_location: dropoff_location}) do
    GoogleMaps.open_map_url(dropoff_location)
  end

  def open_map_url(%Campaign{location: location}) do
    GoogleMaps.open_map_url(location)
  end
end
