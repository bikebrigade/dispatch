defmodule BikeBrigade.Repo.Migrations.EnableSendDeliverySummariesForProgramsWithSlackChannel do
  use Ecto.Migration

  def up do
    execute """
      UPDATE programs SET send_delivery_summaries = true WHERE slack_channel_id IS NOT NULL
    """
  end

  def down, do: :ok
end
