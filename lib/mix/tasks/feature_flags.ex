defmodule Mix.Tasks.FeatureFlags do
  use Mix.Task

  alias BikeBrigade.Riders

  # TODO this should live somewhere else as gigalixir doesn't let me run tasks directly

  @requirements ["app.start"]
  @shortdoc "Opt riders into a feature flag"

  @impl Mix.Task
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
