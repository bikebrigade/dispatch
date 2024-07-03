defmodule BikeBrigade.Repo.Migrations.AddPhotoDescriptionToPrograms do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add(:photo_description, :string)
    end
  end
end
