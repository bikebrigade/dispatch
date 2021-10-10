defmodule BikeBrigade.Repo.Migrations.PopulateRiderIds do
  use Ecto.Migration

  alias BikeBrigade.Repo
  alias BikeBrigade.Riders.Rider
  alias BikeBrigade.Messaging.SmsMessage
  import Ecto.Query

  def up do
    from(m in SmsMessage,
      join: r in Rider,
      on: r.phone == m.to or r.phone == m.from,
      update: [set: [rider_id: r.id, incoming: m.to in ^BikeBrigade.Messaging.all_inbound_numbers()]])
    |> Repo.update_all([])

    drop index(:sms_messages, [:from])
    drop index(:sms_messages, [:to])
  end

  def down do
    create index(:sms_messages, [:from])
    create index(:sms_messages, [:to])
  end
end
