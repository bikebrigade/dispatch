defmodule BikeBrigadeWeb.CommunityFridgeLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Locations

  @impl true
  def update(%{community_fridge: community_fridge} = assigns, socket) do
    changeset = Locations.change_community_fridge(community_fridge)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"community_fridge" => params}, socket) do
    changeset =
      socket.assigns.community_fridge
      |> Locations.change_community_fridge(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"community_fridge" => params}, socket) do
    save_community_fridge(socket, socket.assigns.action, params)
  end

  defp save_community_fridge(socket, :edit, params) do
    case Locations.update_community_fridge(socket.assigns.community_fridge, params) do
      {:ok, _community_fridge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community fridge updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_community_fridge(socket, :new, params) do
    case Locations.create_community_fridge(params) do
      {:ok, _community_fridge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community fridge created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
