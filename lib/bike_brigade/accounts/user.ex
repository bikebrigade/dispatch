defmodule BikeBrigade.Accounts.User do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.EctoPhoneNumber

  defmodule Flags do
    use BikeBrigade.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :unified_messaging, :boolean, default: false
    end

    def changeset(flags, attrs \\ %{}) do
      flags
      |> cast(attrs, [:unified_messaging])
    end
  end

  schema "users" do
    field :email, :string
    field :name, :string
    field :phone, EctoPhoneNumber.Canadian
    field :is_dispatcher, :boolean, default: false
    field :signature_on_messages, :string
    belongs_to :rider, Rider
    embeds_one :flags, Flags, on_replace: :update, defaults_to_struct: true

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :phone, :signature_on_messages])
    |> validate_required([:name, :email, :phone])
    |> unique_constraint(:phone)
    |> unique_constraint(:email)
  end

  @doc "This changeset is to be used by admin users"
  def admin_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:is_dispatcher, :rider_id])
    |> cast_embed(:flags)
  end
end
