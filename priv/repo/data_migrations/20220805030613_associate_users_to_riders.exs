defmodule BikeBrigade.Repo.Migrations.AssociateUsersToRiders do
  use Ecto.Migration
  import Ecto.Query

  def up do
    users =
      from(u in BikeBrigade.Accounts.User,
        join: r in BikeBrigade.Riders.Rider,
        on: u.phone == r.phone,
        update: [set: [rider_id: r.id]]
      )
      |> BikeBrigade.Repo.update_all([])
  end

  def down, do: :ok
end
