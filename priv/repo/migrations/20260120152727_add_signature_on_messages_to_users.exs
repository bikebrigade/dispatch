defmodule BikeBrigade.Repo.Migrations.AddSignatureOnMessagesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :signature_on_messages, :string
    end
  end
end
