defmodule BikeBrigadeWeb.UserLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Accounts
  alias BikeBrigade.Repo

  @impl true
  def update(%{user: user} = assigns, socket) do
    user = Repo.preload(user, :rider)
    changeset = Accounts.change_user_as_admin(user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:user, user)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user_as_admin(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    # TODO: We should probably not allow users to have no rider associated
    # But for now let's make it possible for consistency
    user_params = Map.put_new(user_params, "rider_id", nil)

    case Accounts.update_user_as_admin(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.create_user_as_admin(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp signature_preview(changeset) do
    case Ecto.Changeset.get_field(changeset, :signature_on_messages) do
      nil -> "<name>"
      "" -> "<name>"
      signature -> signature
    end
  end
end
