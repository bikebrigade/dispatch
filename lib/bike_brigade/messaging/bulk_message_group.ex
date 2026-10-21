defmodule BikeBrigade.Messaging.BulkMessageGroup do
  use BikeBrigade.Schema
  import Ecto.Changeset

  schema "bulk_message_groups" do
    field :name, :string
    field :body, :string
    belongs_to :creator, BikeBrigade.Accounts.User

    many_to_many :riders, BikeBrigade.Riders.Rider,
      join_through: "bulk_message_group_riders",
      join_keys: [group_id: :id, rider_id: :id],
      on_replace: :delete

    timestamps()
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :body])
    |> validate_required([:name, :body])
    |> validate_length(:name, max: 100)
    |> validate_length(:body, max: 1600)
  end
end
