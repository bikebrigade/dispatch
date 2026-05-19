defmodule BikeBrigade.Repo.Migrations.EnableSendDeliverySummariesForProgramsWithSlackChannel do
  use Ecto.Migration
  import Ecto.Query

  alias BikeBrigade.Repo

  def up do
    from(prog in BikeBrigade.Delivery.Program,
      update: [set: [send_delivery_summaries: true]],
      where: not is_nil(prog.slack_channel_id)
    )
    |> Repo.update_all([])
  end

  def down, do: :ok
end
