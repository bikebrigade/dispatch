defmodule Mix.Tasks.FeatureFlags do
  use Mix.Task

  alias BikeBrigade.{Accounts, Riders}
  alias BikeBrigade.Accounts.User
  alias BikeBrigade.Riders.Rider

  # TODO this should live somewhere else as gigalixir doesn't let me run tasks directly

  @requirements ["app.start"]
  @shortdoc "Opt riders or users into a feature flag"

  @moduledoc """
  Rolls a feature flag out to a percentage of riders or users.

      mix feature_flags <rider_flag> <0|25|50|75|100>
      mix feature_flags users <user_flag> <0|25|50|75|100>

  Buckets are deterministic per flag and ID. `0` turns the flag off for everyone;
  other percentages only turn it on, so individual opt-ins are kept.
  """

  @percentages ["0", "25", "50", "75", "100"]

  @impl Mix.Task
  def run(["users", flag, opt_in]) when opt_in in @percentages do
    with {:ok, flag} <- fetch_flag(User.Flags, flag) do
      rollout(Accounts.list_users(), flag, opt_in, &Accounts.update_user_as_admin/2)
    end
  end

  def run([flag, opt_in]) when opt_in in @percentages do
    with {:ok, flag} <- fetch_flag(Rider.Flags, flag) do
      rollout(Riders.list_riders(), flag, opt_in, &Riders.update_rider/2)
    end
  end

  # Only flags defined on the schema can be set; anything else would be silently dropped.
  defp fetch_flag(schema, name) do
    flags = schema.__schema__(:fields)

    case Enum.find(flags, &(Atom.to_string(&1) == name)) do
      nil ->
        Mix.shell().error("Unknown flag #{inspect(name)}. Known flags: #{Enum.join(flags, ", ")}")
        :error

      flag ->
        {:ok, flag}
    end
  end

  defp rollout(records, flag, opt_in, update) do
    updates =
      case opt_in do
        "0" ->
          for r <- records, do: {r, %{flags: %{flag => false}}}

        "100" ->
          for r <- records, do: {r, %{flags: %{flag => true}}}

        _ ->
          percentage = String.to_integer(opt_in) / 100
          for r <- records, opt_in(flag, r.id, percentage), do: {r, %{flags: %{flag => true}}}
      end

    for {record, attrs} <- updates do
      with {:error, changeset} <- update.(record, attrs) do
        Mix.shell().error("Could not update #{record.id}: #{inspect(changeset.errors)}")
      end
    end

    Mix.shell().info("Updated #{flag} for #{length(updates)} of #{length(records)}")
  end

  def opt_in(flag, id, percentage) do
    <<x::8, _::bitstring>> = :crypto.hash(:sha, "#{flag}-#{id}")

    x < 255 * percentage
  end
end
