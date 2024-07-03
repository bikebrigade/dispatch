# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :bike_brigade, BikeBrigade.LocalizedDateTime,
  timezone: System.get_env("APP_TZ", "America/Toronto")

config :bike_brigade,
  ecto_repos: [BikeBrigade.Repo]

# UTC everywhere
config :bike_brigade, BikeBrigade.Repo, migration_timestamps: [type: :utc_datetime_usec]

# Geo types
config :bike_brigade, BikeBrigade.Repo, types: BikeBrigade.PostgresTypes

# Configures the endpoint
config :bike_brigade, BikeBrigadeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pcB9K1AsMcibczlVowBtpMGnpBeHfkHBDrizPkBCIMz0tGQwhCw/iL9GEOE0fNIm",
  render_errors: [view: BikeBrigadeWeb.ErrorHTML, accepts: ~w(html json), layout: false],
  pubsub_server: BikeBrigade.PubSub,
  live_view: [signing_salt: "ZvJcZ6yv"],
  static_url: [path: "/static"]

config :reverse_proxy_plug, :http_client, ReverseProxyPlug.HTTPClient.Adapters.HTTPoison

# Analytics reverse proxy
config :bike_brigade, BikeBrigadeWeb.Router,
  analytics_upstream: "http://bike-brigade-analytics.internal:8080/analytics/"

# Esbuild
config :esbuild,
  version: "0.14.8",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Tailwind
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :geo_postgis,
  json_library: Jason

config :bike_brigade, BikeBrigade.Tasks.MailchimpImporter,
  list_id: {:system, "MAILCHIMP_LIST_ID"}

  config :bike_brigade, BikeBrigade.Tasks.MailchimpAttributesSync,
  list_id: {:system, "MAILCHIMP_LIST_ID"}

# We use the same phone number for our authentication and regular messaging by they are configurable separately for now
config :bike_brigade, BikeBrigade.Messaging,
  outbound_number: {:system, "PHONE_NUMBER", default: "647-555-5555"},
  new_outbound_number: {:system, "NEW_PHONE_NUMBER", default: "647-555-5555"},
  inbound_numbers: {:system, "INBOUND_NUMBERS", default: "647-555-5555"}

config :bike_brigade, BikeBrigade.AuthenticationMessenger, phone_number: {:system, "PHONE_NUMBER", default: "647-555-5555"}

# Config our google clients
config :bike_brigade, BikeBrigade.GoogleMaps, api_key: {:system, "GOOGLE_MAPS_API_KEY", default: ""}

# Set slack channel IDs for messaging
config :bike_brigade, BikeBrigade.Messaging.Slack.Operations,
  channel_id: "C022R3HU9B9",
  channel_name: "api-playground"

config :bike_brigade, BikeBrigade.Messaging.Slack.RiderSms,
  channel_id: "C022R3HU9B9",
  channel_name: "api-playground"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
