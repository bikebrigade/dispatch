defmodule BikeBrigadeWeb.CampaignLive.New do
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.Campaign

  alias NimbleCSV.RFC4180, as: CSV

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :campaigns)
     |> assign(:page_title, "New Campaign")
     |> assign(:campaign, %Campaign{})
     |> assign(:changeset, Delivery.change_campaign(%Campaign{}))
     |> assign(:delivery_spreadsheet, nil)
     |> allow_upload(:delivery_spreadsheet,
       accept: ~w(.csv),
       progress: &handle_progress/3,
       auto_upload: true
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"campaign" => campaign_params}, socket) do
    IO.inspect campaign_params

    changeset =
      socket.assigns.campaign
      |> Delivery.change_campaign(campaign_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", params, socket) do
    IO.inspect params
    {:noreply, socket}
  end
  defp handle_progress(:delivery_spreadsheet, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          File.read!(path)
          |> CSV.parse_string(skip_headers: false)
        end)

      {:noreply, socket |> assign(:delivery_spreadsheet, uploaded_file)}
    else
      {:noreply, socket}
    end
  end

  defp pickup_location(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.fetch_field!(changeset, :pickup_location)
  end
end
