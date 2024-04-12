import Config

# Set Endpoint and repo configs if we're in production
case config_env() do
  :dev ->
    DotenvParser.load_file(".env.local")

    if System.get_env("CODESPACES") == "true" do
      config :bike_brigade, BikeBrigade.Repo, hostname: "postgres"
    end

    case System.get_env("SLACK_OAUTH_TOKEN") do
      nil ->
        config :bike_brigade, :slack,
          token: "token",
          adapter: BikeBrigade.SlackApi.FakeSlack

      token ->
        config :bike_brigade, :slack,
          token: token,
          adapter: BikeBrigade.SlackApi.Http
    end

    case {System.get_env("TWILIO_ACCOUNT_SID"), System.get_env("TWILIO_AUTH_TOKEN"),
          System.get_env("TWILIO_STATUS_CALLBACK")} do
      {sid, token, url} when is_binary(sid) and is_binary(token) and is_binary(url) ->
        config :ex_twilio,
          account_sid: sid,
          auth_token: token

        config :bike_brigade, :sms_service,
          adapter: BikeBrigade.SmsService.Twilio,
          status_callback_url: url

      {_, _, _} ->
        config :bike_brigade, :sms_service,
          adapter: BikeBrigade.SmsService.FakeSmsService,
          status_callback_url: :local
    end

    case System.get_env("GOOGLE_MAPS_API_KEY") do
      api_key when is_binary(api_key) and api_key != "" ->
        config :bike_brigade, :geocoder, adapter: BikeBrigade.Geocoder.LibLatLonGeocoder

      _ ->
        config :bike_brigade, :geocoder,
          adapter: {BikeBrigade.Geocoder.FakeGeocoder, [locations: :from_seeds]}
    end

    case System.get_env("GOOGLE_SERVICE_JSON") do
      json when is_binary(json) and json != "" ->
        config :bike_brigade, BikeBrigade.Google, credentials: json

        case System.get_env("GOOGLE_STORAGE_BUCKET") do
          nil ->
            config :bike_brigade, :media_storage,
              adapter: BikeBrigade.MediaStorage.LocalMediaStorage,
              bucket: "bike-brigade-media"

          bucket ->
            config :bike_brigade, :media_storage,
              adapter: BikeBrigade.MediaStorage.GoogleMediaStorage,
              bucket: bucket
        end

      _no_json ->
        config :bike_brigade, :media_storage,
          adapter: BikeBrigade.MediaStorage.LocalMediaStorage,
          bucket: "bike-brigade-media"
    end

    case System.get_env("MAILCHIMP_API_KEY") do
      nil ->
        config :bike_brigade, :mailchimp, adapter: BikeBrigade.MailchimpApi.FakeMailchimp

      key ->
        config :bike_brigade, :mailchimp, adapter: BikeBrigade.MailchimpApi.Http
        config :mailchimp, api_key: key
    end

  :prod ->
    app_env =
      case System.get_env("APP_ENV") do
        "production" -> :production
        "staging" -> :staging
      end

    config :bike_brigade, :app_env, app_env

    database_url =
      System.get_env("DATABASE_URL") ||
        raise """
        environment variable DATABASE_URL is missing.
        For example: ecto://USER:PASS@HOST/DATABASE
        """

    config :bike_brigade, BikeBrigade.Repo,
      url: database_url,
      ssl: false,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

    secret_key_base =
      System.get_env("SECRET_KEY_BASE") ||
        raise """
        environment variable SECRET_KEY_BASE is missing.
        You can generate one by calling: mix phx.gen.secret
        """

    config :bike_brigade, BikeBrigadeWeb.Endpoint,
      server: true,
      http: [
        port: String.to_integer(System.get_env("PORT") || "4000"),
        # IMPORTANT: support IPv6 addresses
        transport_options: [socket_opts: [:inet6]]
      ],
      secret_key_base: secret_key_base

    app_name =
      System.get_env("FLY_APP_NAME") ||
        raise "FLY_APP_NAME not available"

    config :libcluster,
      debug: true,
      topologies: [
        fly6pn: [
          strategy: Cluster.Strategy.DNSPoll,
          config: [
            polling_interval: 5_000,
            query: "#{app_name}.internal",
            node_basename: app_name
          ]
        ]
      ]

    # Production / staging differences
    case app_env do
      :production ->
        config :bike_brigade, BikeBrigadeWeb.Endpoint,
          url: [host: "dispatch.bikebrigade.ca", port: 443, scheme: "https"]

        config :bike_brigade, BikeBrigade.Messaging.Slack.Operations,
          channel_id: "C016VGHETS4",
          channel_name: "software"

        config :bike_brigade, BikeBrigade.Messaging.Slack.RiderSms,
          channel_id: "C01QU0YVACW",
          channel_name: "dispatch"

        # Honeybadger
        config :honeybadger,
          app: :bike_brigade,
          use_logger: true,
          breadcrumbs_enabled: true,
          ecto_repos: [BikeBrigade.Repo]

        # Task Runners
        config :bike_brigade, BikeBrigade.TaskRunner,
          start: true,
          checkin_url: {:system, "TASK_RUNNER_CHECKIN_URL"}

      :staging ->
        config :bike_brigade, BikeBrigade.Repo, socket_options: [:inet6]

        config :bike_brigade, BikeBrigadeWeb.Endpoint,
          url: [host: "staging.bikebrigade.ca", port: 443]

        config :bike_brigade, BikeBrigade.PromEx,
          manual_metrics_start_delay: :no_delay,
          grafana: [
            host: System.get_env("GRAFANA_HOST") || raise("GRAFANA_HOST is required"),
            username: System.get_env("GRAFANA_USERNAME") || raise("GRAFANA_USERNAME is required"),
            password: System.get_env("GRAFANA_PASSWORD") || raise("GRAFANA_PASSWORD is required"),
            upload_dashboards_on_start: true,
            folder_name: "Bike Brigade Dashboards",
            annotate_app_lifecycle: true
          ],
          metrics_server: [
            port: 4021,
            path: "/metrics",
            protocol: :http,
            pool_size: 5,
            cowboy_opts: [],
            auth_strategy: :none
          ]

        config :bike_brigade, :sms_service, block_non_dispatch_messages: true

        config :bike_brigade, BikeBrigade.Messaging.Slack.Operations,
          channel_id: "C022R3HU9B9",
          channel_name: "api-playground"

        config :bike_brigade, BikeBrigade.Messaging.Slack.RiderSms,
          channel_id: "C022R3HU9B9",
          channel_name: "api-playground"
    end

    # Google
    config :bike_brigade, BikeBrigade.Google,
      credentials: System.fetch_env!("GOOGLE_SERVICE_JSON")

    # Slack
    config :bike_brigade, :slack, token: System.fetch_env!("SLACK_OAUTH_TOKEN")

    # Geocoding
    config :lib_lat_lon, :provider, LibLatLon.Providers.GoogleMaps

    config :lib_lat_lon,
           :google_maps_api_key,
           System.get_env("GOOGLE_MAPS_API_KEY") ||
             raise("environment variable GOOGLE_MAPS_API_KEY is missing.")

    # Twilio
    config :ex_twilio,
      account_sid: System.fetch_env!("TWILIO_ACCOUNT_SID"),
      auth_token: System.fetch_env!("TWILIO_AUTH_TOKEN")

    # SmsService
    config :bike_brigade, :sms_service,
      status_callback_url: System.fetch_env!("TWILIO_STATUS_CALLBACK")

    # Mailchimp
    config :mailchimp,
      api_key: System.fetch_env!("MAILCHIMP_API_KEY")

  _ ->
    nil
end

# LibLatLon uses porcelain with the basic driver so we don't need to worry about goon
config :porcelain, goon_warn_if_missing: false
