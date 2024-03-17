defmodule BikeBrigade.Delivery.CampaignRider do
  use BikeBrigade.Schema

  import Ecto.Changeset

  alias BikeBrigade.Delivery.Campaign
  alias BikeBrigade.Riders.Rider

  schema "campaigns_riders" do
    belongs_to :campaign, Campaign
    belongs_to :rider, Rider

    field :rider_capacity, :integer, default: 1
    field :notes, :string
    field :pickup_window, :string
    field :enter_building, :boolean, default: false
    field :token, :string
    field :rider_signed_up, :boolean, default: false

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [
      :campaign_id,
      :rider_id,
      :rider_capacity,
      :notes,
      :pickup_window,
      :enter_building,
      :rider_signed_up
    ])
    |> maybe_gen_token()
    # TODO this required validation for :campaign_id may be not needed
    |> validate_required([:campaign_id, :rider_id, :rider_capacity, :enter_building, :token])
    |> unique_constraint([:campaign_id, :rider_id])
    |> unique_constraint(:token)
  end

  def maybe_gen_token(changeset) do
    case fetch_field(changeset, :token) do
      {:data, token} when not is_nil(token) -> changeset
      _ -> gen_token_changeset(changeset)
    end
  end

  def gen_token_changeset(struct_or_changeset) do
    change(struct_or_changeset, %{token: gen_token()})
  end

  defp gen_token() do
    :crypto.strong_rand_bytes(10)
    |> Base.encode32()
    |> String.downcase()
  end
end
