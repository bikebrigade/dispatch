defmodule BikeBrigadeWeb.CampaignLive.DuplicateCampaignComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.{Delivery, Repo, Messaging}

  def render(assigns) do
    ~H"""
      <div>
      <h2>Duplicate campaign</h2>
      <%= live_component C.FlashComponent, flash: @flash %>
      <.form
        let={f}
        for={:duplicate_form}
        id="duplicate-campaign-form"
        phx-target={@myself}

        phx-submit="duplicate">
        <div class="flex my-2 mt-4 space-x-2">
          <div>
            <%= label f, :delivery_date, class: "block text-sm font-medium leading-5 text-gray-700" do %>
              New Delivery Date
            <% end %>
            <div class="my-1 rounded-md shadow-sm" >
              <%= date_input f, :delivery_date, value: LocalizedDateTime.to_date(@campaign.delivery_start), class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
            </div>
            <%= error_tag f, :delivery_date %>
          </div>
          <div>
            <%= label f, :start_time, class: "block text-sm font-medium leading-5 text-gray-700" do %>
              Start
            <% end %>
            <div class="my-1 rounded-md shadow-sm" >
              <%= time_input f, :start_time, value: LocalizedDateTime.to_time(@campaign.delivery_start),  class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
            </div>
            <%= error_tag f, :start_time %>
          </div>
          <div>
            <%= label f, :end_time, class: "block text-sm font-medium leading-5 text-gray-700" do %>
              End
            <% end %>
            <div class="my-1 rounded-md shadow-sm" >
              <%= time_input f, :end_time, value: LocalizedDateTime.to_time(@campaign.delivery_end), class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
            </div>
            <%= error_tag f, :end_time %>
          </div>
        </div>
        <div class="flex justify-end mt-2">
          <C.button type="submit" phx-disable-with="Saving...">
            Duplicate
          </C.button>
        </div>
      </.form>
      </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("duplicate", %{"duplicate_form" => duplicate_form}, socket) do
    old_campaign = socket.assigns.campaign

    {:ok, new_campaign} = create_new_campaign(old_campaign, duplicate_form)

    if old_campaign.instructions_template_id do
      copy_instructions_template(old_campaign, new_campaign)
    end

    {:noreply, socket
      |> put_flash(:info, "Campaign duplicated successfully")
      |> push_redirect(to: socket.assigns.return_to)}
  end

  defp create_new_campaign(old_campaign, duplicate_form_params) do
    %{
      "delivery_date" => delivery_date,
      "start_time" => start_time,
      "end_time" => end_time
    } = duplicate_form_params

    delivery_date = Date.from_iso8601!(delivery_date)
    start_time = Time.from_iso8601!("#{start_time}:00")
    end_time = Time.from_iso8601!("#{end_time}:00")

    campaign_attrs = Delivery.Campaign.fields_for(old_campaign)
      |> Map.put(:delivery_start, LocalizedDateTime.new!(delivery_date, start_time))
      |> Map.put(:delivery_end, LocalizedDateTime.new!(delivery_date, end_time))

    Delivery.create_campaign(campaign_attrs)
  end

  defp copy_instructions_template(old_campaign, new_campaign) do
    old_campaign =
      old_campaign
      |> Repo.preload(:instructions_template)

    new_campaign
    |> Repo.preload(:instructions_template)
    |> Delivery.update_campaign(%{
      instructions_template: %{body: old_campaign.instructions_template.body }
    })
  end
end
