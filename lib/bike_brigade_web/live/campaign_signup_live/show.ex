defmodule BikeBrigadeWeb.CampaignSignupLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
  # import BikeBrigade.Utils, only: [replace_if_updated: 2]
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.CampaignRider

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok,
     socket
     |> assign(:page, :campaign_signup)
     |> assign(:current_rider_id, socket.assigns.current_user.rider_id)
     |> assign(:campaign, nil)
     |> assign(:riders, nil)
     |> assign(:tasks, nil)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    id = String.to_integer(id)
    campaign = Delivery.get_campaign!(id)
    # {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    {:noreply,
     socket
     # |> assign(:campaign, campaign)
     # |> assign(:tasks, tasks)
     # |> assign(:riders, riders)
     |> assign_campaign(campaign)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _) do
    socket
    |> assign(:page_title, "Campaign Signup")
  end

  defp apply_action(socket, _, _), do: socket

  defp split_first_name(full_name) do
    case String.split(full_name, " ") do
      [first_name, last_name] when is_binary(first_name) and is_binary(last_name) ->
        first_name

      _ ->
        full_name
    end
  end

  @impl true
  def handle_event("assign_task", %{"task_id" => task_id, "rider_id" => rider_id}, socket) do
    # TODO: this will be removed and handled by a modal form.
    campaign_rider = %{
      "campaign_id" => socket.assigns.campaign.id,
      "enter_building" => false,
      "pickup_window" => "1-2",
      "rider_capacity" => "1",
      "rider_id" => rider_id
    }

    case Delivery.create_campaign_rider(campaign_rider) do
      {:ok, _cr} ->
        {:ok, _task} =
          get_task(socket, task_id)
          |> Delivery.update_task(%{assigned_rider_id: rider_id})

        {:noreply, socket}

      {:error, _e} ->
        {:noreply,
         socket |> put_flash(:error, "Unable to add you to this campaign.")}

    end
  end

  @impl true
  def handle_event("unassign_task", %{"task_id" => task_id}, socket) do
    task = get_task(socket, task_id)
    rider_id = socket.assigns.current_user.rider_id

    if task.assigned_rider do
      {:ok, _task} =
        task
        |> Delivery.update_task(%{assigned_rider_id: nil})
    end

    # If rider is no longer assigned to any tasks, remove them from the campaign
    rider_has_no_other_tasks? =
      socket.assigns.tasks
      # remove the task that was just clicked
      |> Enum.reject(fn t -> t.id === task_id end)
      # if the rider's is not found in any other of the tasks, return true.
      |> Enum.filter(fn t -> t.assigned_rider_id == rider_id end)
      |> Enum.empty?()

    if rider_has_no_other_tasks? do
      Delivery.remove_rider_from_campaign(socket.assigns.campaign, rider_id)
    end

    {:noreply, socket}
  end

  # TODO: move this into a shared guards / macros file? It is used in campaign_live/show.ex
  defmacrop belongs_to_campaign?(campaign, task) do
    quote do
      unquote(task).campaign_id == unquote(campaign).id
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:task_updated, updated_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    {:noreply, socket |> assign_campaign(socket.assigns.campaign)}
  end

  @impl true
  def handle_info({:campaign_rider_created, %CampaignRider{campaign_id: campaign_id}}, socket) do
    %{campaign: campaign} = socket.assigns

    # REVIEW: in campaign_live/show.ex we are pushing leaflet; do we want to do that here despite
    # there not actually being a map on this view? I suppose if we did, that would live update the map
    # on the dispatcher side, should they be looking at campaign_live/show when someone signs up.
    if campaign_id == campaign.id do
      {:noreply, assign_campaign(socket, campaign)}
    else
      {:noreply, socket}
    end
  end

  # REVIEW: not sure if this needs the pattern match like sit does in campaign_signup/show
  def handle_info({:campaign_rider_deleted, _}, socket) do
    campaign = socket.assigns.campaign
    {:noreply, assign_campaign(socket, campaign)}
  end

  ## lil helpers

  defp get_task(socket, id) when is_binary(id), do: get_task(socket, String.to_integer(id))

  defp get_task(socket, id) when is_integer(id),
    do: Enum.find(socket.assigns.tasks, nil, fn x -> x.id == id end)

  defp assign_campaign(socket, campaign) do
    {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    socket
    |> assign(:campaign, campaign)
    |> assign(:riders, riders)
    |> assign(:tasks, tasks)
  end

  ## Module specific components

  defp get_delivery_size(assigns) do
    item_list =
      Enum.map(assigns.task.task_items, fn task_item ->
        "#{task_item.count} #{task_item.item.category}"
      end)

    assigns = assign(assigns, :item_list, item_list)

    ~H"""
    <div :for={item <- @item_list}>
      <%= item %>
    </div>
    """
  end

  defp truncated_riders_notes(assigns) do
    if String.length(assigns.note) > 40 do
      ~H"""
      <div class="w-[40ch] flex items-center">
        <details>
          <summary class="cursor-pointer"><%= String.slice(@note, 0..40) %>...</summary>
          <%= @note %>
        </details>
      </div>
      """
    else
      ~H"""
      <div><%= @note %></div>
      """
    end
  end
end
