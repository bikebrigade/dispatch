defmodule BikeBrigade.Repo.Migrations.AddSentByUserToSmsMessages do
  use Ecto.Migration

  def change do
    alter table(:sms_messages) do
      add :sent_by_user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
