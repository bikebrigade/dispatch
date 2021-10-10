defmodule BikeBrigade.Analytics.Rider do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "analytics_riders" do
    field :availability, :map
    field :capacity, :integer
    field :mailchimp_id, :string
    field :mailchimp_status, :string
    field :max_distance, :integer
    field :onfleet_account_status, :string
    field :onfleet_id, :string
    field :pronouns, :string
    field :contact_id, :id

    timestamps()
  end

  @doc false
  def changeset(rider, attrs) do
    rider
    |> cast(attrs, [:onfleet_id, :onfleet_account_status, :pronouns, :availability, :capacity, :max_distance, :mailchimp_id, :mailchimp_status])
    |> validate_required([:onfleet_id, :onfleet_account_status, :pronouns, :availability, :capacity, :max_distance, :mailchimp_id, :mailchimp_status])
  end
end
