defmodule BikeBrigade.Repo.Migrations.AddSlackChannelIdToPrograms do
  use Ecto.Migration

  def change do
    alter table(:programs) do
      add :slack_channel_id, :string
    end
  end
end
