defmodule BikeBrigadeWeb.CampaignLive.DuplicateCampaignComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.LocalizedDateTime

  alias BikeBrigade.{Delivery, Repo}

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    date = LocalizedDateTime.to_date(assigns.campaign.delivery_start)

    already_exists =
      Delivery.campaign_exists_for_program_on_date?(
        assigns.campaign.program_id,
        date,
        assigns.campaign.id
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:delivery_date, date)
     |> assign(:already_exists, already_exists)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.flash kind={:info} title="Success!" flash={@flash} />
      <.flash kind={:warn} title="Warning!" flash={@flash} />
      <.flash kind={:error} title="Error!" flash={@flash} />
      <.header>{@title}</.header>
      <div :if={@already_exists} class="p-4 my-4 rounded-md bg-yellow-50">
        <div class="flex">
          <div class="flex-shrink-0">
            <Heroicons.exclamation_triangle mini class="w-5 h-5 text-yellow-400" />
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-yellow-800">
              A campaign for this program already exists on {Calendar.strftime(@delivery_date, "%B %-d, %Y")}
            </h3>
            <p class="mt-1 text-sm text-yellow-700">
              Are you sure you want to create another one?
            </p>
          </div>
        </div>
      </div>
      <.simple_form
        :let={f}
        for={%{}}
        as={:duplicate_form}
        id="duplicate-campaign-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="duplicate"
      >
        <div class="flex my-2 mt-4 space-x-2">
          <.inputs_for :let={d} field={f[:date_time_form]}>
            <.input
              type="date"
              field={d[:delivery_date]}
              label="New Delivery Date"
              value={@delivery_date}
            />
            <.input
              type="time"
              field={d[:start_time]}
              label="Start"
              value={LocalizedDateTime.to_time(@campaign.delivery_start)}
            />
            <.input
              type="time"
              field={d[:end_time]}
              label="End"
              value={LocalizedDateTime.to_time(@campaign.delivery_end)}
            />
          </.inputs_for>
        </div>

        <.input type="checkbox" checked field={f[:duplicate_deliveries]} label="Copy Deliveries" />
        <.input type="checkbox" field={f[:duplicate_riders]} label="Copy Riders" />

        <:actions>
          <.button type="submit" phx-disable-with="Saving...">
            Duplicate
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"duplicate_form" => params}, socket) do
    date_str = get_in(params, ["date_time_form", "delivery_date"])
    campaign = socket.assigns.campaign

    {delivery_date, already_exists} =
      case Date.from_iso8601(date_str || "") do
        {:ok, date} ->
          {date,
           Delivery.campaign_exists_for_program_on_date?(
             campaign.program_id,
             date,
             campaign.id
           )}

        _ ->
          {socket.assigns.delivery_date, false}
      end

    {:noreply,
     socket
     |> assign(:delivery_date, delivery_date)
     |> assign(:already_exists, already_exists)}
  end

  def handle_event("duplicate", %{"duplicate_form" => duplicate_form_params}, socket) do
    %{
      "date_time_form" => date_time_form_params,
      "duplicate_deliveries" => duplicate_deliveries,
      "duplicate_riders" => duplicate_riders
    } = duplicate_form_params

    old_campaign = socket.assigns.campaign

    {:ok, new_campaign} = create_new_campaign(old_campaign, date_time_form_params)

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
     |> push_navigate(to: socket.assigns.navigate)}
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
    old_campaign = old_campaign |> Repo.preload(tasks: [:pickup_location, :dropoff_location])

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
