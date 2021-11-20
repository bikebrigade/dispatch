defmodule BikeBrigade.Delivery.Opportunity do
  use Ecto.Schema
  import Ecto.Changeset

  alias BikeBrigade.Delivery.Program

  schema "delivery_opportunities" do
    field :delivery_end, :utc_datetime_usec
    field :delivery_start, :utc_datetime_usec
    field :hide_address, :boolean, default: false
    field :published, :boolean, default: false
    field :signup_link, :string
    field :campaign_id, :id

    belongs_to :program, Program

    timestamps()
  end

  @doc false
  def changeset(opportunity, attrs) do
    opportunity
    |> cast(attrs, [:program_id, :delivery_start, :delivery_end, :signup_link, :published, :hide_address])
    |> validate_required([:program_id, :delivery_start, :delivery_end, :signup_link, :published])
  end
end
