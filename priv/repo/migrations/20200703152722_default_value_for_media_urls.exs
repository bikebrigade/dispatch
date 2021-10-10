defmodule BikeBrigade.Repo.Migrations.DefaultValueForMediaUrls do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      remove :media_urls
      add :media_urls, {:array, :string}, defualt: []
    end
  end
end
