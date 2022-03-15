defmodule BikeBrigadeWeb.CampaignLive.DuplicateCampaignComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.{Delivery, Repo}

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
      <div>
      <C.flash_component flash={@flash} />
      <.form
        let={f}
        for={:duplicate_form}
        id="duplicate-campaign-form"
        phx-target={@myself}
        phx-submit="duplicate">
        <%= for d <- inputs_for(f, :date_time_form) do %>
          <div class="flex my-2 mt-4 space-x-2">
            <div>
              <%= label d, :delivery_date, class: "block text-sm font-medium leading-5 text-gray-700" do %>
                New Delivery Date
              <% end %>
              <div class="my-1 rounded-md shadow-sm" >
                <%= date_input d, :delivery_date, value: LocalizedDateTime.to_date(@campaign.delivery_start), class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
              </div>
              <%= error_tag d, :delivery_date %>
            </div>
            <div>
              <%= label d, :start_time, class: "block text-sm font-medium leading-5 text-gray-700" do %>
                Start
              <% end %>
              <div class="my-1 rounded-md shadow-sm" >
                <%= time_input d, :start_time, value: LocalizedDateTime.to_time(@campaign.delivery_start),  class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
              </div>
              <%= error_tag d, :start_time %>
            </div>
            <div>
              <%= label d, :end_time, class: "block text-sm font-medium leading-5 text-gray-700" do %>
                End
              <% end %>
              <div class="my-1 rounded-md shadow-sm" >
                <%= time_input d, :end_time, value: LocalizedDateTime.to_time(@campaign.delivery_end), class: "block w-full px-3 py-2 placeholder-gray-400 transition duration-150 ease-in-out border border-gray-300 rounded-md appearance-none focus:outline-none focus:ring-blue focus:border-blue-300 sm:text-sm sm:leading-5"  %>
              </div>
              <%= error_tag d, :end_time %>
            </div>
          </div>
        <% end %>
        <div class="mt-4 space-y-4">
          <div class="relative flex items-start">
            <div class="flex items-center h-5">
              <%= checkbox f, :duplicate_deliveries, value: true, phx_debounce: "blur", class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
            </div>
            <div class="ml-3 text-sm">
              <%= label f, :duplicate_deliveries, class: "font-medium text-gray-700" do %>
                Copy Deliveries
              <% end %>
            </div>
          </div>
        </div>
        <div class="mt-4 space-y-4">
          <div class="relative flex items-start">
            <div class="flex items-center h-5">
              <%= checkbox f, :duplicate_riders, value: true, phx_debounce: "blur", class: "w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" %>
            </div>
            <div class="ml-3 text-sm">
              <%= label f, :duplicate_riders, class: "font-medium text-gray-700" do %>
                Copy Riders
              <% end %>
            </div>
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
  def handle_event("duplicate", %{"duplicate_form" => duplicate_form_params}, socket) do
    %{
      "date_time_form" => date_time_form_params,
      "duplicate_deliveries" => duplicate_deliveries,
      "duplicate_riders" => duplicate_riders
    } = duplicate_form_params

    old_campaign = socket.assigns.campaign

    {:ok, new_campaign} = create_new_campaign(old_campaign, date_time_form_params)

    if old_campaign.location_id do
      copy_location(old_campaign, new_campaign)
    end

    if old_campaign.instructions_template_id do
      copy_instructions_template(old_campaign, new_campaign)
    end

    if duplicate_deliveries == "true" do
      copy_delivery_tasks(old_campaign, new_campaign)
    end

    if duplicate_riders == "true" do
      copy_campaign_riders(old_campaign, new_campaign)
    end

    {:noreply,
     socket
     |> put_flash(:info, "Campaign duplicated successfully")
     |> push_redirect(to: socket.assigns.return_to)}
  end

  defp create_new_campaign(old_campaign, date_time_form_params) do
    %{
      "delivery_date" => delivery_date,
      "start_time" => start_time,
      "end_time" => end_time
    } = date_time_form_params

    delivery_date = Date.from_iso8601!(delivery_date)
    start_time = Time.from_iso8601!("#{start_time}:00")
    end_time = Time.from_iso8601!("#{end_time}:00")

    campaign_attrs =
      Delivery.Campaign.fields_for(old_campaign)
      |> Map.put(:delivery_start, LocalizedDateTime.new!(delivery_date, start_time))
      |> Map.put(:delivery_end, LocalizedDateTime.new!(delivery_date, end_time))

    Delivery.create_campaign(campaign_attrs)
  end

  defp copy_location(old_campaign, new_campaign) do
    old_campaign =
      old_campaign
      |> Repo.preload(:location)

    new_campaign
    |> Repo.preload(:location)
    |> Delivery.update_campaign(%{
      location: Map.from_struct(new_campaign.location)
    })
  end

  defp copy_instructions_template(old_campaign, new_campaign) do
    old_campaign =
      old_campaign
      |> Repo.preload(:instructions_template)

    new_campaign
    |> Repo.preload(:instructions_template)
    |> Delivery.update_campaign(%{
      instructions_template: %{body: old_campaign.instructions_template.body}
    })
  end

  defp copy_delivery_tasks(old_campaign, new_campaign) do
    old_campaign =
      old_campaign
      |> Repo.preload(:tasks)

    for old_task <- old_campaign.tasks do
      task_params =
        Delivery.Task.fields_for(old_task)
        |> Map.drop([:delivery_status, :delivery_status_notes])

      {:ok, new_task} = Delivery.create_task_for_campaign(new_campaign, task_params)

      old_task = old_task |> Repo.preload(:task_items)

      for task_item <- old_task.task_items do
        %Delivery.TaskItem{}
        |> Delivery.TaskItem.changeset(%{
          task_id: new_task.id,
          item_id: task_item.item_id,
          count: task_item.count
        })
        |> Repo.insert()
      end
    end
  end

  defp copy_campaign_riders(old_campaign, new_campaign) do
    old_campaign =
      old_campaign
      |> Repo.preload(:campaign_riders)

    for campaign_rider <- old_campaign.campaign_riders do
      Delivery.create_campaign_rider(%{
        campaign_id: new_campaign.id,
        rider_id: campaign_rider.rider_id,
        rider_capacity: campaign_rider.rider_capacity,
        pickup_window: campaign_rider.pickup_window,
        enter_building: campaign_rider.enter_building,
        notes: campaign_rider.notes
      })
    end
  end
end
