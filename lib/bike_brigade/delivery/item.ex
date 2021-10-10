defmodule BikeBrigade.Delivery.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias BikeBrigade.Delivery.Program

  @categories [
    :"Foodshare Box",
    :"Prepared Food",
    :"Food Hamper",
    :"Groceries",
    :"Other"
  ]

  schema "items" do
    field :category, Ecto.Enum, values: @categories
    field :description, :string
    field :name, :string
    field :photo, :string
    field :plural_name, :string

    belongs_to :program, Program

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:program_id, :name, :plural_name, :description, :category, :photo])
    |> validate_required([:program_id, :name, :category])
  end
end
