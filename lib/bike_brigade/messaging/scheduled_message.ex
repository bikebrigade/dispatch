defmodule BikeBrigade.Messaging.ScheduledMessage do
  use BikeBrigade.Schema

  alias BikeBrigade.Delivery.Campaign

  import Ecto.Changeset

  schema "scheduled_messages" do
    field :send_at, :utc_datetime
    belongs_to :campaign, Campaign

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:send_at, :campaign_id])
  end
end
