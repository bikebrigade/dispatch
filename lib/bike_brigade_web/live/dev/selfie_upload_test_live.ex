defmodule BikeBrigadeWeb.Dev.SelfieUploadTestLive do
  @moduledoc """
  Throwaway page (/dev/selfie_upload) for trying files against the selfie upload
  on staging. Not for main: it uploads to the real selfie Drive folder.

  "Upload as selfie" runs `BikeBrigade.Selfies.upload/3` exactly as the delivery
  page does. "Upload anyway" skips detection so rejected files (e.g. HEIF
  sequences) can be checked in Drive.
  """
  use BikeBrigadeWeb, :live_view

  alias BikeBrigade.Google.Drive
  alias BikeBrigade.Selfies

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :dev_selfie_upload)
     |> assign(:page_title, "Selfie upload test")
     |> assign(:results, [])
     |> allow_upload(:photo, accept: :any, max_entries: 1, max_file_size: 20_000_000)}
  end

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  def handle_event("upload", %{"mode" => mode}, socket) do
    user = socket.assigns.current_user

    [result] =
      consume_uploaded_entries(socket, :photo, fn %{path: path}, entry ->
        detected = Selfies.detect_content_type(path)

        {:ok,
         %{file: entry.client_name, detected: detected, drive: upload(mode, path, entry, user)}}
      end)

    {:noreply, update(socket, :results, &[result | &1])}
  end

  defp upload("selfie", path, _entry, user) do
    rider = %{name: "TEST #{user.name}"}
    campaign = %{delivery_start: DateTime.utc_now(), program: %{name: "selfie upload test"}}
    Selfies.upload(path, rider, campaign)
  end

  defp upload("anyway", path, entry, user) do
    content_type =
      case Selfies.detect_content_type(path) do
        {:ok, type} -> type
        {:error, _} -> raw_content_type(path, entry)
      end

    with {:ok, file} <-
           Drive.upload_file(path, Selfies.folder(),
             name: "TEST #{user.name} - #{entry.client_name}",
             content_type: content_type
           ) do
      {:ok, Map.put(file, "uploadedAs", content_type)}
    end
  end

  # For files the detector rejects: label HEIF sequences per IANA, otherwise
  # trust the browser
  defp raw_content_type(path, entry) do
    case File.open!(path, [:read, :binary], &IO.binread(&1, 12)) do
      <<_::32, "ftyp", brand::binary-size(4)>> when brand in ~w(hevc hevx hevm hevs) ->
        "image/heic-sequence"

      <<_::32, "ftyp", "msf1">> ->
        "image/heif-sequence"

      _ ->
        if entry.client_type in [nil, ""], do: "application/octet-stream", else: entry.client_type
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto flex max-w-2xl flex-col gap-6 p-4">
      <.header>
        Selfie upload test
        <:subtitle>
          Staging only. Files go to the real selfie Drive folder, named "TEST …".
        </:subtitle>
      </.header>

      <form id="selfie-test-form" phx-change="validate" class="flex flex-col gap-4">
        <.live_file_input upload={@uploads.photo} class="file-input w-full" />

        <div :for={entry <- @uploads.photo.entries} class="flex flex-col gap-2">
          <span class="text-sm break-all">
            {entry.client_name} ({entry.client_type || "no MIME type"}, {entry.client_size} bytes)
          </span>
          <progress class="progress progress-primary w-full" value={entry.progress} max="100" />
          <p :for={err <- upload_errors(@uploads.photo, entry)} class="alert alert-error">
            {inspect(err)}
          </p>
          <div class="flex flex-wrap gap-2">
            <.button
              type="button"
              phx-click="upload"
              phx-value-mode="selfie"
              disabled={!entry.done?}
            >
              Upload as selfie
            </.button>
            <.button
              type="button"
              phx-click="upload"
              phx-value-mode="anyway"
              disabled={!entry.done?}
            >
              Upload anyway
            </.button>
            <button type="button" class="btn btn-ghost" phx-click="cancel" phx-value-ref={entry.ref}>
              Remove
            </button>
          </div>
        </div>
      </form>

      <div :for={result <- @results} class="card bg-base-200">
        <div class="card-body gap-2 text-sm">
          <h2 class="card-title text-base break-all">{result.file}</h2>
          <p>Detected: <code>{inspect(result.detected)}</code></p>
          <%= case result.drive do %>
            <% {:ok, file} -> %>
              <p :if={file["uploadedAs"]}>Uploaded as: <code>{file["uploadedAs"]}</code></p>
              <a href={file["webViewLink"]} target="_blank" class="link link-primary">
                Open in Drive
              </a>
            <% {:error, reason} -> %>
              <p class="text-error">Not uploaded: <code>{inspect(reason)}</code></p>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
