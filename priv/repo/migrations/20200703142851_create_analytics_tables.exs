defmodule BikeBrigade.Repo.Migrations.CreateAnalyticsTables do
  use Ecto.Migration

  def change do
    create table(:analytics_addresses) do
      add(:line1, :string)
      add(:line2, :string)
      add(:city, :string)
      add(:province, :string)
      add(:postal, :string)
      add(:country, :string)
      add(:geo, :geography)

      timestamps()
    end


    flush()

    create table(:analytics_contacts) do
      add(:name, :string)
      add(:email, :string)
      add(:phone, :string)
      add(:address, references(:analytics_addresses, on_delete: :nothing))

      timestamps()
    end

    create(index(:analytics_contacts, [:address]))

    flush()

    create table(:analytics_riders) do
      add(:onfleet_id, :string)
      add(:onfleet_account_status, :string)
      add(:pronouns, :string)
      add(:availability, :map)
      add(:capacity, :integer)
      add(:max_distance, :integer)
      add(:mailchimp_id, :string)
      add(:mailchimp_status, :string)
      add(:contact_id, references(:analytics_contacts, on_delete: :nothing))

      timestamps()
    end

    create(index(:analytics_riders, [:contact_id]))

    create table(:analytics_tasks) do
      add(:rider_notes, :text)
      add(:submitted_on, :utc_datetime)
      add(:organiation_name, :string)
      add(:onfleet_pickup_id, :string)
      add(:onfleet_dropoff_id, :string)
      add(:request_type, :string)
      add(:other_items, :string)
      add(:size, :integer)
      add(:delivery_date, :date)
      add(:delivery_window, :string)
      add(:delivery_distance, :integer)
      add(:rider_id, references(:analytics_riders, on_delete: :nothing))
      add(:pickup_contact_id, references(:analytics_contacts, on_delete: :nothing))
      add(:pickup_address, references(:analytics_addresses, on_delete: :nothing))
      add(:dropoff_contact_id, references(:analytics_contacts, on_delete: :nothing))
      add(:dropoff_address, references(:analytics_addresses, on_delete: :nothing))

      timestamps()
    end

    create(index(:analytics_tasks, [:rider_id]))
    create(index(:analytics_tasks, [:pickup_contact_id]))
    create(index(:analytics_tasks, [:pickup_address]))
    create(index(:analytics_tasks, [:dropoff_contact_id]))
    create(index(:analytics_tasks, [:dropoff_address]))

    create table(:analytics_campaigns) do
      add(:name, :string)
      add(:delivery_date, :date)

      timestamps()
    end

    flush()

    create table(:analytics_campaign_tasks) do
      add(:campaign_id, references(:analytics_campaigns, on_delete: :nothing))
      add(:task_id, references(:analytics_tasks, on_delete: :nothing))

      timestamps()
    end

    create(index(:analytics_campaign_tasks, [:campaign_id]))
    create(index(:analytics_campaign_tasks, [:task_id]))

    create table(:analytics_campaign_riders) do
      add(:capacity, :integer)
      add(:pickup_window, :string)
      add(:campaign_id, references(:analytics_campaigns, on_delete: :nothing))
      add(:rider_id, references(:analytics_riders, on_delete: :nothing))

      timestamps()
    end

    create(index(:analytics_campaign_riders, [:campaign_id]))
    create(index(:analytics_campaign_riders, [:rider_id]))

    create table(:analytics_campaign_summaries) do
      add(:delivery_window, :string)
      add(:tasks_count, :integer)
      add(:riders_count, :integer)
      add(:distance_covered, :integer)
      add(:failed_count, :integer)
      add(:campaign_id, references(:analytics_campaigns, on_delete: :nothing))

      timestamps()
    end

    create(index(:analytics_campaign_summaries, [:campaign_id]))
  end
end
