defmodule BikeBrigade.Repo.Migrations.CampaignsLatestSmsMessages do
  use Ecto.Migration

  def up do
    sql =
      Path.join(
        :code.priv_dir(:bike_brigade),
        "repo/sql/campaigns_latest_sms_messages_20230210130951.sql"
      )
      |> File.read!()

    execute(sql)
  end

  def down do
    sql = "drop view if exists campaigns_latest_sms_messages"
    execute(sql)
  end
end
