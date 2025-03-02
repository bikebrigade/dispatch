defmodule BikeBrigadeWeb.AnnouncementLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery

  alias BikeBrigadeWeb.CoreComponentsTwo, as: CC2


  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage announcement records in your database.</:subtitle>
      </.header>

      <CC2.simple_form
        for={@form}
        id="announcement-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <CC2.input field={@form[:message]} type="text" label="Message" />
        <CC2.input field={@form[:turn_on_at]} type="datetime-local" label="Turn on at" />
        <CC2.input field={@form[:turn_off_at]} type="datetime-local" label="Turn off at" />
        <CC2.input field={@form[:created_by]} type="text" label="Created by" value={@myself}/>
        <:actions>
          <CC2.button phx-disable-with="Saving...">Save Announcement</CC2.button>
        </:actions>
      </CC2.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{announcement: announcement} = assigns, socket) do
    changeset = Delivery.change_announcement(announcement)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"announcement" => announcement_params}, socket) do
    changeset =
      socket.assigns.announcement
      |> Delivery.change_announcement(announcement_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"announcement" => announcement_params}, socket) do
    IO.inspect socket
    save_announcement(socket, socket.assigns.action, announcement_params)
  end

  defp save_announcement(socket, :edit, announcement_params) do
    case Delivery.update_announcement(socket.assigns.announcement, announcement_params) do
      {:ok, announcement} ->
        notify_parent({:saved, announcement})

        {:noreply,
         socket
         |> put_flash(:info, "Announcement updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_announcement(socket, :new, announcement_params) do
    case Delivery.create_announcement(announcement_params) do
      {:ok, announcement} ->
        notify_parent({:saved, announcement})

        {:noreply,
         socket
         |> put_flash(:info, "Announcement created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
