defmodule BikeBrigadeWeb.ProgramLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.Delivery

  alias BikeBrigadeWeb.ProgramLive.ProgramForm

  @impl Phoenix.LiveComponent
  def update(%{program: program} = assigns, socket) do
    program = BikeBrigade.Repo.preload(program, [:items])
    program_form = ProgramForm.from_program(program)
    changeset = ProgramForm.changeset(program_form)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:program, program)
     |> assign(:program_form, program_form)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add-schedule", _params, socket) do
    changeset = socket.assigns.changeset
    schedules = Ecto.Changeset.get_field(changeset, :schedules) ++ [%ProgramForm.Schedule{}]
    changeset = Ecto.Changeset.put_embed(changeset, :schedules, schedules)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove-schedule", %{"index" => index}, socket) do
    changeset = socket.assigns.changeset

    schedules =
      changeset
      |> Ecto.Changeset.get_field(:schedules)
      |> List.delete_at(String.to_integer(index))

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(:schedules, schedules)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"program_form" => program_form_params}, socket) do
    changeset =
      socket.assigns.program_form
      |> ProgramForm.changeset(program_form_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"program_form" => program_form_params}, socket) do
    save_program(socket, socket.assigns.action, program_form_params)
  end

  defp save_program(socket, :edit, program_form_params) do
    changeset =
      socket.assigns.program_form
      |> ProgramForm.changeset(program_form_params)
    with {:ok, program_params} <-
           ProgramForm.to_program_attributes(changeset),
         {:ok, _program} <- Delivery.update_program(socket.assigns.program, program_params) do
      {:noreply,
       socket
       |> put_flash(:info, "Program updated successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        # TODO this trick is worthy of a blogpost
        {:noreply, assign(socket, :changeset, changeset |> Map.put(:action, :insert))}
    end
  end

  defp save_program(socket, :new, program_form_params) do
    changeset =
      socket.assigns.program_form
      |> ProgramForm.changeset(program_form_params)

    with {:ok, program_params} <-
           ProgramForm.to_program_attributes(changeset),
         {:ok, _program} <- Delivery.create_program(program_params) do
      {:noreply,
       socket
       |> put_flash(:info, "Program created successfully")
       |> push_redirect(to: socket.assigns.return_to)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset |> Map.put(:action, :insert))}
    end
  end
end
