defmodule BikeBrigade.Riders.RidersTag do
  use BikeBrigade.Schema

  alias BikeBrigade.Riders.{Rider, Tag}

  schema "riders_tags" do
    belongs_to :rider, Rider
    belongs_to :tag, Tag

    timestamps()
  end
end
