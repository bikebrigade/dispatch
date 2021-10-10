defmodule BikeBrigade.Repo.Migrations.SmsDefaultsTakeTwo2 do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      add :media_urls, {:array, :string}, default: []
    end
  end
end
