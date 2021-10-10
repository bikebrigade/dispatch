defmodule BikeBrigade.HoneybadgerTelemetry do
  require Logger

  @events [
    [:phoenix, :live_view, :mount, :start],
    [:phoenix, :live_view, :handle_params, :start],
    [:phoenix, :live_view, :handle_event, :start],
    [:phoenix, :live_component, :handle_event, :start]
  ]

  def attach do
    case :telemetry.attach_many(__MODULE__, @events, &handle_event/4, nil) do
      :ok ->
        Logger.debug("#{__MODULE__} attached to #{inspect(@events)}")
        :ok

      {:error, _} = error ->
        Logger.warn("failed to attach to Phoenix events: #{inspect(error)}")

        error
    end
  end

  def handle_event(
        [:phoenix, :live_view, :mount, :start],
        _measurements,
        %{socket: socket, params: params, session: session},
        _config
      ) do
    put_plug_env(socket, params, session)

    Honeybadger.add_breadcrumb("mount",
      category: "live_view",
      metadata: %{
        params: inspect(params)
      }
    )
  end

  def handle_event(
        [:phoenix, :live_view, :handle_params, :start],
        _measurements,
        %{params: params},
        _config
      ) do
    update_plug_env_params(params)

    Honeybadger.add_breadcrumb("handle_params",
      category: "live_view",
      metadata: %{
        params: inspect(params)
      }
    )
  end

  def handle_event(
        [:phoenix, :live_view, :handle_event, :start],
        _measurements,
        %{event: event, params: params},
        _config
      ) do
    Honeybadger.add_breadcrumb("handle_event \"#{event}\"",
      category: "live_view",
      metadata: %{
        params: inspect(params)
      }
    )
  end

  def handle_event(
        [:phoenix, :live_component, :handle_event, :start],
        _measurements,
        %{event: event, component: component, params: params},
        _config
      ) do
    Honeybadger.add_breadcrumb("handle_event \"#{event}\"",
      category: "live_component",
      metadata: %{
        component: module_to_string(component),
        params: inspect(params)
      }
    )
  end

  defp put_plug_env(socket, params, _session) do
    # This is a hack to make sure we have a `:context` key in out context, so that HoneyBadger reports our `plug_env` outside of it
    if Honeybadger.context()[:context] == nil do
      Honeybadger.context(context: %{})
    end

    Honeybadger.context(
      plug_env: %{
        component: module_to_string(socket.view),
        action: socket.assigns.live_action,
        params: params,
        session: %{}, # Not sending session for now
        url: URI.to_string(socket.host_uri)
      }
    )
  end

  defp update_plug_env_params(params) do
    (Honeybadger.context()[:plug_env] || %{})
    |> Map.put(:params, params)
    |> Honeybadger.context()
  end

  # Copied from Honeybadger.Utils for portability
  defp module_to_string(module) do
    module
    |> Module.split()
    |> Enum.join(".")
  end
end
