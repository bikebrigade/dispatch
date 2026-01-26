defmodule BikeBrigade.Riders.Tag do
  use BikeBrigade.Schema

  alias BikeBrigade.Riders.{Rider, RidersTag}

  schema "tags" do
    field :name, :string
    field :restricted, :boolean, default: false
    many_to_many :riders, Rider, join_through: RidersTag

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> Ecto.Changeset.cast(params, [:name, :restricted])
    |> Ecto.Changeset.validate_required([:name])
  end
end
