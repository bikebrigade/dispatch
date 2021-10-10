defmodule BikeBrigade.Messaging.Template do
  use BikeBrigade.Schema

 # alias BikeBrigade.Messaging.SmsMessage

  import Ecto.Changeset

  schema "message_templates" do
    field :body, :string
    # TODO clean this up, we dont need a model for this it turns out :(
    #has_many :messages, SmsMessage

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body])
  #  |> cast_assoc(:messages, required: false)
  end
end
