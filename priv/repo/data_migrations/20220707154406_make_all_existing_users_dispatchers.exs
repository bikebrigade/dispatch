defmodule BikeBrigade.Repo.Migrations.MakeAllExistingUsersDispatchers do
  use Ecto.Migration
  import Ecto.Query

  alias BikeBrigade.Repo

  def up do
    from(u in BikeBrigade.Accounts.User, update: [set: [is_dispatcher: true]])
    |> Repo.update_all([])
  end

  def down, do: :ok
end
