defmodule BikeBrigade.Repo.Migrations.ProgramFields do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :campaign_blurb, :text
    end
  end
end
