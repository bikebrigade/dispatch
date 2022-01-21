defmodule BikeBrigade.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Start the Ecto repository
        BikeBrigade.Repo,
        # Start the Telemetry supervisor
        BikeBrigadeWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: BikeBrigade.PubSub},
        # Provide user presence
        BikeBrigade.Presence,
        # Start the Endpoint (http/https)
        BikeBrigadeWeb.Endpoint,

        # Maintain state of text-based authentication codes
        BikeBrigade.AuthenticationMessenger,

        # Send scheduled campaign messgaes
        BikeBrigade.ScheduledMessenger
      ]
      |> BikeBrigade.Importers.Runner.append_child_spec()
      |> BikeBrigade.Google.append_child_spec()
      |> BikeBrigade.SlackApi.append_child_spec()
      |> BikeBrigade.SmsService.append_child_spec()
      |> BikeBrigade.Geocoder.append_child_spec()
      |> BikeBrigade.MediaStorage.append_child_spec()
      |> BikeBrigade.MailchimpApi.append_child_spec()

    # Hook up telemetry to Honeybadger
    BikeBrigade.HoneybadgerTelemetry.attach()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BikeBrigade.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BikeBrigadeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
