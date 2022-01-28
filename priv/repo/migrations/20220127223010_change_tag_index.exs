defmodule BikeBrigade.Repo.Migrations.ChangeTagIndex do
  use Ecto.Migration

  def change do
    drop(unique_index(:riders_tags, [:tag_id, :rider_id]))
    create(unique_index(:riders_tags, [:rider_id, :tag_id]))
  end
end
