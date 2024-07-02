import Config

config :bike_brigade, :environment, :test

database_url =
  System.get_env("DATABASE_URL")

if database_url do
  config :bike_brigade, BikeBrigade.Repo, url: database_url, pool: Ecto.Adapters.SQL.Sandbox
else
  # The MIX_TEST_PARTITION environment variable can be used
  # to provide built-in test partitioning in CI environment.
  # Run `mix help test` for more information.
  config :bike_brigade, BikeBrigade.Repo,
    username: "postgres",
    password: "postgres",
    database: "bike_brigade_test#{System.get_env("MIX_TEST_PARTITION")}",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bike_brigade, BikeBrigadeWeb.Endpoint,
  http: [port: 4002],
  server: true,
  static_url: [path: "/static"]

# Print only warnings and errors during test
config :logger, level: :warning

# Don't run importers
config :bike_brigade, BikeBrigade.TaskRunner, start: false

config :honeybadger,
  environment_name: :test

# Don't use google stuff
config :goth, disabled: true

config :bike_brigade, :slack,
  token: "token",
  adapter: BikeBrigade.SlackApi.FakeSlack

config :bike_brigade, :sms_service,
  adapter: BikeBrigade.SmsService.FakeSmsService,
  status_callback_url: :local

config :bike_brigade, :geocoder,
  adapter: {BikeBrigade.Geocoder.FakeGeocoder, [locations: :from_seeds]}

config :bike_brigade, :media_storage,
  adapter: BikeBrigade.MediaStorage.FakeMediaStorage,
  bucket: "bike-brigade-public"

config :bike_brigade, :mailchimp, adapter: BikeBrigade.MailchimpApi.FakeMailchimp

config :bike_brigade, :sandbox, Ecto.Adapters.SQL.Sandbox
