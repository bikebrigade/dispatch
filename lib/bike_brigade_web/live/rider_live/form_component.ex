defmodule BikeBrigadeWeb.RiderLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Riders
  alias BikeBrigade.Repo

  @impl true
  def update(%{rider: rider} = assigns, socket) do
    rider = rider |> Repo.preload(:tags)
    changeset = Riders.change_rider(rider)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rider, rider)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"rider" => rider_params}, socket) do
    changeset =
      socket.assigns.rider
      |> Riders.change_rider(rider_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"rider" => rider_params}, socket) do
    save_rider(socket, socket.assigns.action, rider_params)
  end

  defp save_rider(socket, :edit, rider_params) do
    case Riders.update_rider(socket.assigns.rider, rider_params) do
      {:ok, _rider} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rider updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_rider(socket, :new, rider_params) do
    case Riders.create_rider(rider_params) do
      {:ok, _rider} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rider created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def humanized_tags(tags) do
    Enum.map(tags, & &1.name)
    |> Enum.join(",")
  end
end
