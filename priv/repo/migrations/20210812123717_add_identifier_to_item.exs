defmodule BikeBrigade.Repo.Migrations.AddIdentifierToItem do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :identifier, :string
    end
  end
end
