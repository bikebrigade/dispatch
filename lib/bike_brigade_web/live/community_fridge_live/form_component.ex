defmodule BikeBrigadeWeb.CommunityFridgeLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.{Locations, MediaStorage}

  @impl true
  def mount(socket) do
    {:ok, allow_upload(socket, :photo, accept: ~w(.gif .png .jpg .jpeg), max_entries: 1)}
  end

  @impl true
  def update(%{community_fridge: community_fridge} = assigns, socket) do
    changeset = Locations.change_community_fridge(community_fridge)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"community_fridge" => community_fridge_params}, socket) do
    changeset =
      socket.assigns.community_fridge
      |> Locations.change_community_fridge(community_fridge_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("remove_photo", _params, socket) do
    changeset = Ecto.Changeset.put_change(socket.assigns.changeset, :photo, nil)
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  def handle_event("save", %{"community_fridge" => community_fridge_params}, socket) do
    photo_url =
      case consume_uploaded_entries(socket, :photo, fn %{path: path},
                                                       %{client_type: content_type} ->
             {:ok, MediaStorage.upload_file!(path, content_type)}
           end) do
        [%{url: url}] -> url
        [] -> nil
      end

    community_fridge_params =
      cond do
        photo_url ->
          Map.put(community_fridge_params, "photo", photo_url)

        match?(%{changes: %{photo: nil}}, socket.assigns.changeset) ->
          Map.put(community_fridge_params, "photo", nil)

        true ->
          community_fridge_params
      end

    save_community_fridge(socket, socket.assigns.action, community_fridge_params)
  end

  defp save_community_fridge(socket, :edit, community_fridge_params) do
    case Locations.update_community_fridge(
           socket.assigns.community_fridge,
           community_fridge_params
         ) do
      {:ok, _community_fridge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community fridge updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_community_fridge(socket, :new, community_fridge_params) do
    case Locations.create_community_fridge(community_fridge_params) do
      {:ok, _community_fridge} ->
        {:noreply,
         socket
         |> put_flash(:info, "Community fridge created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
