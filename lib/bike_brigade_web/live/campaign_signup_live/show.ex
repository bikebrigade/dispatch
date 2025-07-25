defmodule BikeBrigadeWeb.CampaignSignupLive.Show do
  alias BikeBrigade.LocalizedDateTime
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
         campaign when not is_nil(campaign) <- Delivery.get_campaign(num),
         true <- public?(campaign) do
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

  defp first_name_and_last_initial(full_name) do
    case String.split(full_name, " ", parts: 2) do
      [first_name, last_name] when is_binary(first_name) and is_binary(last_name) ->
        "#{first_name} #{String.first(last_name)}"

      [first_name] ->
        first_name
    end
  end

  @impl true
  def handle_event("unassign_task", %{"task_id" => task_id}, socket) do
    task = get_task(socket, task_id)
    rider_id = socket.assigns.current_user.rider_id

    if task.assigned_rider do
      {:ok, _task} =
        task
        |> Delivery.unassign_task(socket.assigns.current_user.id)
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
        {:ok, _task} = Delivery.assign_task(task, rider_id, socket.assigns.current_user.id)
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
    tasks = Enum.sort_by(tasks, fn t -> Locations.neighborhood(t.dropoff_location) end)

    socket
    |> assign(:campaign, campaign)
    |> assign(:riders, riders)
    |> assign(:tasks, tasks)
  end

  ## Module specific components

  defp get_delivery_size(assigns) do
    ~H"""
    <div :for={task_item <- @task.task_items} class="flex items-center">
      <%= if task_item.item.description && task_item.item.description != "" do %>
        <div class="flex items-center">
          <details>
            <summary class="cursor-pointer" title={task_item.item.description}>
              <span :if={task_item.count > 1} class="mr-1">{task_item.count}</span>{Inflex.inflect(
                task_item.item.name,
                task_item.count
              )}
            </summary>
            {task_item.item.description}
          </details>
        </div>
      <% else %>
        {Inflex.inflect(task_item.item.name, task_item.count)}
      <% end %>
    </div>
    """
  end

  @doc """
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
    <div class="flex flex-col space-y-2 md:items-center md:space-y-0 md:flex-row md:space-x-2">
      <%= if @task.assigned_rider do %>
        <div :if={@task.assigned_rider.id != @current_rider_id}>
          {first_name_and_last_initial(@task.assigned_rider.name)}
        </div>

        <div :if={@task.assigned_rider.id == @current_rider_id}>
          You
        </div>
        <.button
          :if={task_eligigle_for_unassign?(@task, @campaign, @current_rider_id)}
          data-confirm={
            if campaign_today?(@campaign),
              do:
                "This delivery starts today. If you need to unassign yourself, please also text dispatch to let us know!"
          }
          phx-click={JS.push("unassign_task", value: %{task_id: @task.id})}
          id={"#{@id}-unassign-task-#{@task.id}"}
          color={:red}
          size={:xsmall}
          class="w-full md:w-28"
        >
          Unassign me
        </.button>
      <% end %>

      <%= if task_eligible_for_signup?(@task, @campaign) do %>
        <.button
          phx-click={
            JS.push("signup_rider", value: %{task_id: @task.id, rider_id: @current_rider_id})
          }
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
          class="w-full cursor-not-allowed md:w-28 bg-neutral-100 text-neutral-800"
        >
          Campaign over
        </.button>
      <% end %>
    </div>
    """
  end

  defp task_eligible_for_signup?(task, campaign) do
    # campaign not in past, assigned rider not nil.
    task.assigned_rider == nil && !campaign_in_past(campaign)
  end

  # determine if a rider is eligible to "unassign" themselves
  defp task_eligigle_for_unassign?(task, campaign, current_rider_id) do
    task.assigned_rider.id == current_rider_id && !campaign_in_past(campaign)
  end

  defp campaign_today?(campaign) do
    LocalizedDateTime.to_date(campaign.delivery_start) == LocalizedDateTime.today()
  end

  def initials(name) do
    name
    |> String.split(~r/[\s+|-]/, trim: true)
    |> Enum.map(&String.first/1)
    |> Enum.map(&String.upcase/1)
    |> Enum.join()
  end
end
