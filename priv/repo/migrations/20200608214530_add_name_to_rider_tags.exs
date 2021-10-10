defmodule BikeBrigade.Repo.Migrations.ConstaintTags do
  use Ecto.Migration

  def change do
    alter table(:riders_tags) do
      modify(:tag_id, references(:tags, on_delete: :delete_all), from: references(:tags))
      modify(:rider_id, references(:riders, on_delete: :delete_all), from: references(:riders))
    end
  end
end
