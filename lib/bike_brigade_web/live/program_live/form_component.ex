defmodule BikeBrigadeWeb.ProgramLive.FormComponent do
  use BikeBrigadeWeb, :live_component

  alias BikeBrigade.{Delivery, MediaStorage, SlackApi}

  alias BikeBrigadeWeb.ProgramLive.ProgramForm

  @impl Phoenix.LiveComponent
  def mount(socket) do
    slack_channels = load_slack_channels()

    socket =
      socket
      |> allow_upload(:photos, accept: ~w(.gif .png .jpg .jpeg), max_entries: 10)
      |> assign(:slack_channels, slack_channels)

    {:ok, socket}
  end

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
  def handle_event("add_schedule", _params, socket) do
    changeset = socket.assigns.changeset
    schedules = Ecto.Changeset.get_field(changeset, :schedules) ++ [%ProgramForm.Schedule{}]
    changeset = Ecto.Changeset.put_embed(changeset, :schedules, schedules)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_schedule", %{"index" => index}, socket) do
    changeset = socket.assigns.changeset

    schedules =
      changeset
      |> Ecto.Changeset.get_field(:schedules)
      |> List.delete_at(index)

    changeset =
      changeset
      |> Ecto.Changeset.put_embed(:schedules, schedules)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add_item", _params, socket) do
    changeset = socket.assigns.changeset

    program =
      Ecto.Changeset.get_field(changeset, :program)

    changeset =
      changeset
      |> Ecto.Changeset.change(
        program:
          program
          |> Ecto.Changeset.change(items: program.items ++ [%{program_id: program.id}])
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove_item", %{"index" => index}, socket) do
    changeset = socket.assigns.changeset
    program = Ecto.Changeset.get_field(changeset, :program)

    items =
      program.items
      |> List.delete_at(index)
      |> Enum.map(&Map.from_struct/1)

    changeset =
      changeset
      |> Ecto.Changeset.change(
        program:
          program
          |> Delivery.Program.changeset(%{items: items})
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("delete_photo", %{"index" => index}, socket) do
    changeset = socket.assigns.changeset
    program = Ecto.Changeset.get_field(changeset, :program)

    photos =
      program.photos
      |> List.delete_at(index)

    changeset =
      changeset
      |> Ecto.Changeset.change(
        program:
          program
          |> Delivery.Program.changeset(%{photos: photos})
      )

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
    photos =
      consume_uploaded_entries(socket, :photos, fn %{path: path}, %{client_type: content_type} ->
        # TODO do some guards on content type here
        {:ok, MediaStorage.upload_file!(path, content_type)}
      end)

    photo_urls = Enum.map(photos, &Map.get(&1, :url))

    program_form_params =
      program_form_params
      |> update_in(
        ["program", "photos"],
        fn
          nil ->
            photo_urls

          photos when is_list(photos) ->
            photos ++ photo_urls
        end
      )

    save_program(socket, socket.assigns.action, program_form_params)
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
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
       |> push_navigate(to: socket.assigns.navigate)}
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
       |> push_navigate(to: socket.assigns.navigate)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset |> Map.put(:action, :insert))}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp load_slack_channels() do
    try do
      channels = SlackApi.list_channels()

      channels
      |> Enum.filter(fn channel ->
        String.starts_with?(channel["name"], "campaigns") || channel["name"] == "api-playground"
      end)
      |> Enum.map(fn channel ->
        {channel["name"], channel["id"]}
      end)
      |> Enum.sort_by(fn {name, _id} -> name end)
    rescue
      _ -> []
    end
  end
end
