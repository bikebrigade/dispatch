defmodule BikeBrigade.Repo.Migrations.CleanupTasks2 do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :submitted_on
      remove :size
      remove :dropoff_organization
      remove :dropoff_email
      remove :onfleet_dropoff_id
      remove :organization_name
      remove :contact_name
      remove :contact_email
      remove :contact_phone
      remove :request_type
      remove :other_items
      remove :delivery_window
      remove :onfleet_pickup_id
    end

    rename table(:tasks), :organization_partner, to: :partner_tracking_id
  end
end
