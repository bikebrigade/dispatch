defmodule BikeBrigadeWeb.CampaignSignupLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
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
     |> assign(:page_title, "Signup for deliveries")
     |> assign(:current_rider_id, socket.assigns.current_user.rider_id)
     |> assign(:campaign, nil)
     |> assign(:riders, nil)
     |> assign(:tasks, nil)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    with {num, ""} <- Integer.parse(id),
         campaign when not is_nil(campaign) <- Delivery.get_campaign(num) do
      {:noreply,
       socket
       |> assign_campaign(campaign)
       |> apply_action(socket.assigns.live_action, params)}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid campaign id.")
         |> redirect(to: ~p"/campaigns/signup/")}
    end
  end

  defp apply_action(socket, :new, _) do
    socket |> assign(:page_title, "Campaign Signup")
  end

  defp apply_action(socket, :rider_signup, %{"task_id" => task_id}) do
    with {num, ""} <- Integer.parse(task_id),
         task when not is_nil(task) <- Delivery.get_task(num) do
      socket
      |> assign(:page_title, "Signup for this delivery")
      |> assign(:task, task)
    else
      _ ->
        socket
        |> put_flash(:error, "Invalid task id.")
        |> redirect(to: ~p"/campaigns/signup/#{socket.assigns.campaign}")
    end
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
        {:noreply, socket |> put_flash(:error, "Unable to add you to this campaign.")}
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

  ## -- Callbacks to handle Delivery broadcasts --

  @impl Phoenix.LiveView
  def handle_info({:campaign_rider_created, %CampaignRider{campaign_id: campaign_id}}, socket) do
    %{campaign: campaign} = socket.assigns

    if campaign_id == campaign.id do
      {:noreply, assign_campaign(socket, campaign)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:campaign_rider_deleted, %CampaignRider{campaign_id: campaign_id}}, socket) do
    %{campaign: campaign} = socket.assigns

    if campaign_id == campaign.id do
      {:noreply, assign_campaign(socket, campaign)}
    else
      {:noreply, socket}
    end
  end

  ## TODO: use pattern match with when guard to do this all in one (like in index)

  def handle_info({:task_updated, updated_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    {:noreply, socket |> assign_campaign(socket.assigns.campaign)}
  end

  def handle_info({:task_created, updated_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    {:noreply, socket |> assign_campaign(socket.assigns.campaign)}
  end

  def handle_info({:task_deleted, updated_task}, socket)
      when belongs_to_campaign?(socket.assigns.campaign, updated_task) do
    {:noreply, socket |> assign_campaign(socket.assigns.campaign)}
  end

  # noop for when tasks aren't connected to the current campaign.
  def handle_info({:task_deleted, _}, socket), do: {:noreply, socket}
  def handle_info({:task_updated, _}, socket), do: {:noreply, socket}
  def handle_info({:task_created, _}, socket), do: {:noreply, socket}

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
