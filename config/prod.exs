import Config

config :bike_brigade, :environment, :prod

config :bike_brigade, BikeBrigadeWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true]

# Adapters
config :bike_brigade, :slack, adapter: BikeBrigade.SlackApi.Http

config :bike_brigade, :sms_service, adapter: BikeBrigade.SmsService.Twilio

config :bike_brigade, :geocoder, adapter: BikeBrigade.Geocoder.LibLatLonGeocoder

config :bike_brigade, BikeBrigade.Google, start: true

# Importers
config :bike_brigade, BikeBrigade.Importers.Runner,
  start: true,
  checkin_url: {:system, "IMPORTER_CHECKIN_URL"}

config :logger, level: :info
