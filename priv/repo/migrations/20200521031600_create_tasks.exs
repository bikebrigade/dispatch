defmodule BikeBrigade.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :submitted_on, :naive_datetime
      add :organization_name, :string
      add :contact_name, :string
      add :contact_email, :string
      add :contact_phone, :string
      add :request_type, :string
      add :other_items, :string
      add :size, :integer
      add :delivery_date, :date
      add :delivery_window, :string
      add :dropoff_organization, :string
      add :dropoff_name, :string
      add :dropoff_email, :string
      add :dropoff_address, :string
      add :dropoff_address2, :string
      add :dropoff_city, :string
      add :dropoff_province, :string
      add :dropoff_postal, :string
      add :dropoff_location, :geography
      add :driver_notes, :string
      add :logistics_notes, :string
      add :pickup_address, :string
      add :pickup_address2, :string
      add :pickup_city, :string
      add :pickup_province_string, :string
      add :pickup_postal, :string
      add :pickup_country, :string
      add :pickup_loacation, :geography

      timestamps()
    end

  end
end
