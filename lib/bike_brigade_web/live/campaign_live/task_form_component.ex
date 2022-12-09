defmodule BikeBrigadeWeb.CampaignLive.TaskFormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery
  alias BikeBrigade.Delivery.TaskItem

  alias BikeBrigadeWeb.Components.LiveLocation

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    %{task: task, campaign: campaign} = assigns
    task = task |> BikeBrigade.Repo.preload([:pickup_location, :dropoff_location])

    changeset = Delivery.change_task(task)
    task_items = Ecto.Changeset.get_field(changeset, :task_items)

    changeset =
      if task_items == [] do
        changeset
        |> Ecto.Changeset.put_assoc(:task_items, [
          %TaskItem{task_id: task.id, item_id: campaign.program.default_item_id}
        ])
      else
        changeset
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:task, task)
     |> assign(changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_item", _params, socket) do
    changeset = socket.assigns.changeset

    task_items =
      Ecto.Changeset.get_field(changeset, :task_items) ++
        [%TaskItem{task_id: socket.assigns.task.id}]

    changeset = Ecto.Changeset.put_assoc(changeset, :task_items, task_items)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_item", %{"index" => index}, socket) do
    changeset = socket.assigns.changeset

    task_items =
      changeset
      |> Ecto.Changeset.get_field(:task_items)
      |> List.delete_at(index)

    changeset =
      changeset
      |> Ecto.Changeset.put_assoc(:task_items, task_items)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    %{task: task} = socket.assigns

    changeset =
      task
      |> Delivery.change_task(task_params, geocode: true)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "save",
        %{"task" => task_params},
        socket
      ) do
    %{campaign: campaign, action: action} = socket.assigns
    save_task(socket, action, campaign, task_params)
  end

  defp save_task(socket, :new, campaign, task_params) do
    case Delivery.create_task_for_campaign(campaign, task_params, geocode: true) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_task(socket, :edit, _campaign, task_params) do
    %{task: task} = socket.assigns

    case Delivery.update_task(task, task_params, geocode: true) do
      {:ok, _task} ->
        {:noreply,
         socket
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp item_options(items) do
    for p <- items do
      {p.name, p.id}
    end
  end
end
