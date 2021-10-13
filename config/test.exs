import Config

config :bike_brigade, :environment, :test

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bike_brigade, BikeBrigade.Repo,
  username: "postgres",
  password: "postgres",
  database: "bike_brigade_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bike_brigade, BikeBrigadeWeb.Endpoint,
  http: [port: 4002],
  # HACK: this is the IP that the selenium docker container can
  # find the host elixir app at.
  url: [host: "172.17.0.1", port: 4002],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Don't run importers
config :bike_brigade, BikeBrigade.Importers.Runner, start: false

# Don't start google client
config :bike_brigade, BikeBrigade.Google, start: false

config :honeybadger,
  environment_name: :test

# Don't use google stuff
config :goth, disabled: true

config :bike_brigade, :slack,
  webhook_url: System.get_env("SLACK_WEBHOOK_URL", "http://example.com/slack-webhook-url"),
  adapter: BikeBrigade.SlackApi.FakeSlack

config :bike_brigade, :sms_service,
  adapter: BikeBrigade.SmsService.FakeSmsService,
  status_callback_url: :local

config :bike_brigade, :geocoder, adapter: BikeBrigade.Geocoder.FakeGeocoder

config :bike_brigade, :sql_sandbox, true

config :wallaby,
  driver: Wallaby.Selenium,
  selenium: [
    capabilities: %{
      javascriptEnabled: true,
      browserName: "chrome",
      chromeOptions: %{
        args: [
          "--no-sandbox",
          "window-size=1280,800",
          "--disable-gpu",
          "--headless",
          "--fullscreen",
          "--user-agent=Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
        ]
      }
    }
  ]
