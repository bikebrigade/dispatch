defmodule BikeBrigade.Analytics.Campaign do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_campaigns" do
    field :delivery_date, :date
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [:name, :delivery_date])
    |> validate_required([:name, :delivery_date])
  end
end
