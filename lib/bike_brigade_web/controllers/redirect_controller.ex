defmodule BikeBrigadeWeb.RedirectController do
  use BikeBrigadeWeb, :controller

  import BikeBrigade.Utils, only: [get_env: 3]

  def new_rider_guide(conn, _params) do
    url =
      get_env(BikeBrigadeWeb.Router, :new_rider_guide_url, nil) ||
        raise "NEW_RIDER_GUIDE_URL is not configured"

    redirect(conn, external: url)
  end
end
