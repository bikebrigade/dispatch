defmodule BikeBrigade.Repo.Migrations.AddMediaUrlsToSmsMessage do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      add :media_urls, {:array, :string}
    end

  end
end
