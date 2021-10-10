defmodule BikeBrigade.Presence do
  use Phoenix.Presence,
    otp_app: :bike_brigade,
    pubsub_server: BikeBrigade.PubSub

  alias BikeBrigade.Accounts

  def fetch(_topic, presences) do
    users =presences
    |> Map.keys()
    |> Accounts.get_users()

    users_map = for user <- users, into: %{} do
      {"#{user.id}", user}
    end

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users_map[key]}}
    end
  end
end
