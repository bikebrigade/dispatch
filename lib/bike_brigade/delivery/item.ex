defmodule BikeBrigade.Delivery.Item do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Delivery.Program

  @categories [
    :"Foodshare Box",
    :"Prepared Food",
    :"Food Hamper",
    :"Groceries",
    :"Community Fridge",
    :"Other",
    :"Non Deliverable"
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
