defmodule BikeBrigade.Repo do
  use Ecto.Repo,
    otp_app: :bike_brigade,
    adapter: Ecto.Adapters.Postgres
end
