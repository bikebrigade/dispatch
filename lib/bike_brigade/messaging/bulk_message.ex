defmodule BikeBrigade.Messaging.BulkMessage do
  @moduledoc """
  A message sent to several riders at once (each rider receives it individually),
  optionally saving the riders as a `BulkMessageGroup`. Not persisted.
  """
  use BikeBrigade.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :rider_ids, {:array, :integer}, default: []
    field :body, :string
    field :campaign_id, :integer
    field :save_group, :boolean, default: false
    field :group_name, :string
    # Attachments are uploaded separately; the body may be empty when there are some.
    field :has_media, :boolean, default: false
  end

  def changeset(bulk_message, attrs) do
    bulk_message
    |> cast(attrs, [:rider_ids, :body, :campaign_id, :save_group, :group_name])
    |> update_change(:body, &String.trim/1)
    |> update_change(:group_name, &String.trim/1)
    |> validate_length(:rider_ids, min: 1, message: "Select at least one rider")
    |> validate_body()
    |> validate_length(:body, max: 1600, message: "Messages can be up to 1600 characters")
    |> validate_group_name()
  end

  defp validate_body(changeset) do
    if get_field(changeset, :has_media),
      do: changeset,
      else: validate_required(changeset, :body, message: "Enter a message")
  end

  defp validate_group_name(changeset) do
    if get_field(changeset, :save_group) do
      changeset
      |> validate_required(:group_name, message: "Enter a name for the group")
      |> validate_length(:group_name,
        max: 100,
        message: "Group names can be up to 100 characters"
      )
    else
      changeset
    end
  end
end
