defmodule BikeBrigade.Google do
  import BikeBrigade.Utils, only: [get_config: 1]

  @scopes [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/drive"
  ]

  def source() do
    credentials =
      case get_config(:credentials)
           |> Jason.decode() do
        {:ok, credentials} -> credentials
        {:error, _err} -> nil
      end

    {:service_account, credentials, scopes: @scopes}
  end
end
