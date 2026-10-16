defmodule Mix.Tasks.FeatureFlags do
  use Mix.Task

  alias BikeBrigade.Riders

  # TODO this should live somewhere else as gigalixir doesn't let me run tasks directly

  @requirements ["app.start"]
  @shortdoc "Manage rider and dispatcher feature flags"

  @impl Mix.Task
  def run(["unified_messaging", opt_in]) when opt_in in ["0", "25", "50", "75", "100"] do
    import Ecto.Query
    percentage = String.to_integer(opt_in) / 100

    for user <-
          BikeBrigade.Repo.all(
            from u in BikeBrigade.Accounts.User, where: u.is_dispatcher == true
          ) do
      enabled =
        opt_in == "100" or (opt_in != "0" and opt_in(:unified_messaging, user.id, percentage))

      flags = Map.put(user.flags || %{}, "unified_messaging", enabled)

      user
      |> BikeBrigade.Accounts.User.admin_changeset(%{flags: flags})
      |> BikeBrigade.Repo.update!()
    end
  end

  def run(["unified_messaging", "user", email, enabled]) when enabled in ["true", "false"] do
    import Ecto.Query
    user = BikeBrigade.Repo.one!(from u in BikeBrigade.Accounts.User, where: u.email == ^email)
    flags = Map.put(user.flags || %{}, "unified_messaging", enabled == "true")

    user
    |> BikeBrigade.Accounts.User.admin_changeset(%{flags: flags})
    |> BikeBrigade.Repo.update!()

    Mix.shell().info("Unified messaging #{enabled} for #{email}")
  end

  def run([flag, opt_in]) when opt_in in ["0", "25", "50", "75", "100"] do
    flag = String.to_atom(flag)

    case opt_in do
      "0" ->
        for r <- Riders.list_riders(), do: Riders.update_rider(r, %{flags: %{flag => false}})

      "25" ->
        for r <- Riders.list_riders(),
            opt_in(flag, r.id, 0.25),
            do: Riders.update_rider(r, %{flags: %{flag => true}})

      "50" ->
        for r <- Riders.list_riders(),
            opt_in(flag, r.id, 0.50),
            do: Riders.update_rider(r, %{flags: %{flag => true}})

      "75" ->
        for r <- Riders.list_riders(),
            opt_in(flag, r.id, 0.75),
            do: Riders.update_rider(r, %{flags: %{flag => true}})

      "100" ->
        for r <- Riders.list_riders(), do: Riders.update_rider(r, %{flags: %{flag => true}})
    end
  end

  def opt_in(flag, id, percentage) do
    <<x::8, _::bitstring>> = :crypto.hash(:sha, "#{flag}-#{id}")

    x < 255 * percentage
  end
end
