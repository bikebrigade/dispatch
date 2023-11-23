defmodule BikeBrigadeWeb.CampaignSignupLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
  import BikeBrigade.Utils, only: [replace_if_updated: 2]
  alias BikeBrigadeWeb.CampaignLive.{TasksListComponent, RidersListComponent}
  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.{Campaign, Task, CampaignRider}
  alias BikeBrigade.Riders.Rider


  @impl true
  def mount(_params, _session, socket) do

    if connected?(socket) do
      Delivery.subscribe()
    end

    {:ok, socket
    |> assign(:page, :campaign_signup)
    |> assign(:current_rider_id, socket.assigns.current_user.rider_id)
    |> assign(:campaign, nil)
    |> assign(:riders, nil)
    |> assign(:tasks, nil)
    }
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    id = String.to_integer(id)
    campaign = Delivery.get_campaign!(id)
    {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)

    {:noreply,
     socket
     |> assign(:campaign, campaign)
     |> assign(:tasks, tasks)
     |> assign(:riders, riders)
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
    {:ok, _task} =
      get_task(socket, task_id)
      |> Delivery.update_task(%{assigned_rider_id: rider_id})

    {:noreply, socket}
  end

  @impl true
  def handle_event("unassign_task", %{"task_id" => task_id}, socket) do
    task = get_task(socket, task_id)

    if task.assigned_rider do
      {:ok, _task} =
        task
        |> Delivery.update_task(%{assigned_rider_id: nil})
    end

    {:noreply, socket}
  end

  defmacrop belongs_to_campaign?(campaign, task) do
    quote do
      unquote(task).campaign_id == unquote(campaign).id
    end
  end


  @impl Phoenix.LiveView
  def handle_info({:task_updated, updated_task}, socket) when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    # REVIEW this is similar to the handle_info in `campaign_live/show` - it's not ideal
    # in that it calls campaign_riders_and_tasks on every signup being clicked.
    %{campaign: campaign} = socket.assigns
    {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    {:noreply,
     socket
     |> assign(:campaign, campaign)
     |> assign(:riders, riders)
     |> assign(:tasks, tasks)
    }
  end

  ## lil helpers

  defp get_task(socket, id) when is_binary(id), do: get_task(socket, String.to_integer(id))
  defp get_task(socket, id) when is_integer(id), do:
    Enum.find(socket.assigns.tasks, nil, fn x -> x.id == id end)


  defp assign_campaign(socket, campaign) do
    {riders, tasks} = Delivery.campaign_riders_and_tasks(campaign)
    socket
    |> assign(:campaign, campaign)
    |> assign(:riders, riders)
    |> assign(:tasks, tasks)
  end


  ## Module specific components

  defp get_delivery_size(assigns) do
    item_list = Enum.map(assigns.task.task_items, fn task_item ->
      "#{task_item.count} #{task_item.item.category}"
    end)

    ~H"""
    <div :for={item <- item_list}>
      <%= item %>
    </div>
    """
  end

  defp truncated_riders_notes(assigns) do
    if String.length(assigns.note) > 40 do
      ~H"""
      <div class="w-[40ch] flex items-center">
      <details >
      <summary class="cursor-pointer"> <%= String.slice(@note, 0..40) %>...</summary>
      <%= @note %>
      </details>
      </div>
      """
    else
      ~H"""
      <div> <%= @note %> </div>
      """
    end
  end
end
