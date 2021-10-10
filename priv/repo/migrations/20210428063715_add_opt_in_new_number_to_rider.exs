defmodule BikeBrigade.Repo.Migrations.AddOptInNewNumberToRider do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :flags, :map, default: %{opt_in_to_new_number: false, initial_message_sent: false}
    end
  end
end
