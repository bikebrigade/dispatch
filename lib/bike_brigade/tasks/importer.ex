defmodule BikeBrigade.Tasks.Importer do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "importers" do
    field :data, :map
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(importer, attrs) do
    importer
    |> cast(attrs, [:name, :data])
    |> validate_required([:name, :data])
  end
end
