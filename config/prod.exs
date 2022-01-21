import Config

config :bike_brigade, :environment, :prod

config :bike_brigade, BikeBrigadeWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  force_ssl: [rewrite_on: [:x_forwarded_proto], hsts: true]

# Adapters
config :bike_brigade, :geocoder, adapter: BikeBrigade.Geocoder.LibLatLonGeocoder

config :bike_brigade, :mailchimp,  BikeBrigade.MailchimpApi.Http

config :bike_brigade, :media_storage,
  bucket: "bike-brigade-public",
  adapter: BikeBrigade.MediaStorage.GoogleMediaStorage

config :bike_brigade, :slack, adapter: BikeBrigade.SlackApi.Http

config :bike_brigade, :sms_service, adapter: BikeBrigade.SmsService.Twilio

config :logger, level: :info
