defmodule BikeBrigade.Repo.Migrations.ChangeDefaultFlags do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      modify :flags, :map, default: %{}
    end
  end
end
