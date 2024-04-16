defmodule BikeBrigadeWeb.CampaignSignupLive.Show do
  use BikeBrigadeWeb, :live_view

  import BikeBrigadeWeb.CampaignHelpers
  alias BikeBrigade.Delivery
  alias BikeBrigade.Locations

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
    with {:parse_int, {num, ""}} <- {:parse_int, Integer.parse(task_id)},
         {:get_task, task} when not is_nil(task) <- {:get_task, Delivery.get_task(num)},
         {:rider_assigned, rider_id} when is_nil(rider_id) <-
           {:rider_assigned, task.assigned_rider_id},
         {:same_campaign, true} <-
           {:same_campaign, task.campaign_id == socket.assigns.campaign.id} do
      socket
      |> assign(:page_title, "Signup for this delivery")
      |> assign(:task, task)
    else
      {:rider_assigned, _} -> rider_signup_redirect(socket)
      {:get_task, nil} -> rider_signup_redirect(socket, "Task does not exist.")
      {:parse_int, :error} -> rider_signup_redirect(socket, "Invalid task id.")
      {:same_campaign, false} -> rider_signup_redirect(socket)
      _ -> rider_signup_redirect(socket, "something went wrong")
    end
  end

  defp apply_action(socket, _, _), do: socket

  defp rider_signup_redirect(socket) do
    socket |> redirect(to: ~p"/campaigns/signup/#{socket.assigns.campaign}")
  end

  defp rider_signup_redirect(socket, flash_msg) do
    socket
    |> put_flash(:error, flash_msg)
    |> redirect(to: ~p"/campaigns/signup/#{socket.assigns.campaign}")
  end

  defp split_first_name(full_name) do
    case String.split(full_name, " ") do
      [first_name, last_name] when is_binary(first_name) and is_binary(last_name) ->
        first_name

      _ ->
        full_name
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

  def handle_event("signup_rider", %{"rider_id" => rider_id, "task_id" => task_id}, socket) do
    %{campaign: campaign, tasks: tasks} = socket.assigns
    task = Enum.find(tasks, fn task -> task.id == task_id end)

    attrs = %{
      # this is arbitrary and not actually used by dispatchers anymore.
      "rider_capacity" => "1",
      # this will need to be configurable at some point, for campaigns that have pickup time edge cases.
      "pickup_window" => pickup_window(campaign),
      "enter_building" => true,
      "campaign_id" => campaign.id,
      "rider_id" => rider_id,
      "rider_signed_up" => true
    }

    case Delivery.create_campaign_rider(attrs) do
      {:ok, _cr} ->
        {:ok, _task} = Delivery.update_task(task, %{assigned_rider_id: rider_id})
        {:noreply, socket |> push_patch(to: ~p"/campaigns/signup/#{campaign}", replace: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  ## -- Callbacks to handle Delivery broadcasts --

  @broadcasted_infos [
    :task_created,
    :task_deleted,
    :task_updated,
    :campaign_rider_created,
    :campaign_rider_deleted
  ]

  @impl Phoenix.LiveView
  def handle_info({event, entity}, socket) when event in @broadcasted_infos do
    campaign = socket.assigns.campaign
    # if a task or a campaign rider changes (ie, if any of the broadcasted_infos)
    # launches from elsewhere, check if the entity's respective campaign id matches
    # the id of the campaign in the current view; if so, refetch the data.
    if entity.campaign_id == campaign.id do
      {:noreply, assign_campaign(socket, campaign)}
    else
      {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  @doc "silently ignore other kinds of messages"
  def handle_info(_, socket), do: {:noreply, socket}

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

  @doc"""
    Shows one of the following:
    - A "Sign up" button if the campaign is eligible for signing up
    - A "Unassign me" button if a rider is assigned to a task and wants to unassign themselves
    - The first name of other riders who have signed up for tasks.
  """

  attr :task, :any, required: true
  attr :campaign, :any, required: true
  attr :current_rider_id, :integer, required: true
  attr :id, :string, required: true
  def signup_button(assigns) do
    ~H"""
    <div>

      <%= if @task.assigned_rider do %>
        <span :if={@task.assigned_rider.id != @current_rider_id} class="mr-2">
          <%= split_first_name(@task.assigned_rider.name) %>
        </span>

        <.button
          :if={task_eligigle_for_unassign(@task, @campaign, @current_rider_id)}
          phx-click={JS.push("unassign_task", value: %{task_id: @task.id})}
          id={"#{@id}-unassign-task-#{@task.id}"}
          color={:red}
          size={:xsmall}
          class="w-full md:w-28"
        >
          Unassign me
        </.button>
      <% end %>

      <%= if task_eligible_for_signup(@task, @campaign) do %>
        <.button
          phx-click={JS.push("signup_rider", value: %{task_id: @task.id, rider_id: @current_rider_id})}
          color={:secondary}
          id={"#{@id}-sign-up-task-#{@task.id}"}
          size={:xsmall}
          class="w-full md:w-28"
          replace
        >
          Sign up
        </.button>
      <% end %>

      <%= if campaign_in_past(@campaign) do %>
        <.button
          color={:secondary}
          id={"#{@id}-task-over-#{@task.id}"}
          size={:xsmall}
          class="w-full md:w-28 cursor-not-allowed bg-neutral-100 text-neutral-800"
        >
          Campaign over
        </.button>
      <% end %>
    </div>
    """
  end

  defp task_eligible_for_signup(task, campaign) do
    # campaign not in past, assigned rider not nil.
    task.assigned_rider == nil && !campaign_in_past(campaign)
  end

  # determine if a rider is eligible to "unassign" themselves
  defp task_eligigle_for_unassign(task, campaign, current_rider_id) do
    task.assigned_rider.id == current_rider_id && !campaign_in_past(campaign)
  end
end
