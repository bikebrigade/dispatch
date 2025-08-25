defmodule BikeBrigade.Repo.Migrations.AddCreatedByIdToBanners do
  use Ecto.Migration

  def change do
    # Only add the column if it doesn't exist
    unless column_exists?(:banners, :created_by_id) do
      alter table(:banners) do
        add :created_by_id, references(:users), null: true
      end
    end
  end
end
