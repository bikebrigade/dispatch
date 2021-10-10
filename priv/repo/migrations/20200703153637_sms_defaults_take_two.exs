defmodule BikeBrigade.Repo.Migrations.SmsDefaultsTakeTwo do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      remove :media_urls
    end
  end
end
