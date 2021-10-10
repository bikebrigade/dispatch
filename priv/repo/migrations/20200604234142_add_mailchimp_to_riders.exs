defmodule BikeBrigade.Repo.Migrations.AddMailchimpToRiders do
  use Ecto.Migration

  def change do
    alter table(:riders) do
      add :mailchimp_id, :string
      add :mailchimp_status, :string
    end
  end
end
