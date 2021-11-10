defmodule BikeBrigade.MixProject do
  use Mix.Project

  def project do
    [
      app: :bike_brigade,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    extras = case Mix.env() do
      :test -> []
      _ -> [:os_mon]
    end
    [
      mod: {BikeBrigade.Application, []},
      extra_applications: [:logger, :runtime_tools, :honeybadger] ++ extras
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "priv/repo/seeds"]
  defp elixirc_paths(:dev), do: ["lib", "priv/repo/seeds"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.2"},
      {:phoenix_ecto, "~> 4.4.0"},
      {:ecto_sql, "~> 3.6.2"},
      {:ecto_psql_extras, "~> 0.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.17.5"},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6.0"},
      {:reverse_proxy_plug, "~> 2.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:httpoison, "~> 1.6"},
      {:nimble_csv, "~> 0.7.0"},
      {:ex_phone_number, "~> 0.2"},
      {:ecto_enum, "~> 1.4.0"},
      {:geo_postgis, "~> 3.3.1"},
      {:lib_lat_lon, "~> 0.4"},
      {:ex_twilio, "~> 0.9.1"},
      # the author has yet to publish this, but it gives us get list by id: https://github.com/duartejc/mailchimp/pull/20
      {:mailchimp,
       git: "https://github.com/duartejc/mailchimp",
       ref: "32a6f2c5649d581201c1dea975b8a97e76a1816f"},
      {:google_api_drive, "~> 0.22.1"},
      {:google_api_storage, "~> 0.29.0"},
      {:google_api_sheets, "~> 0.29.0"},
      {:goth, "~> 1.3-rc", override: true},
      {:faker, "~> 0.13"},
      {:mustache, "~> 0.3.0"},
      {:honeybadger, "~> 0.16.3"},
      {:recase, "~> 0.5"},
      {:heroicons, "~> 0.2.4"},
      {:linkify, git: "https://github.com/mveytsman/linkify", ref: "42c1aca5da2c2ab28abf8f304b211c2a5d2c89c7"},
      {:crontab, "~> 1.1"},
      {:tzdata, "~> 1.1"},
      {:benchee, "~> 1.0.1"},
      {:logflare_logger_backend, "~> 0.11.0"},
      {:prom_ex, "~> 1.4.1"},
      {:esbuild, "~> 0.3.0", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},

      # LiveBook Stuff
      {:kino, "~> 0.3.0"},
      {:vega_lite, "~> 0.1.2"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "assets.deploy": ["esbuild default --minify", "cmd npm run deploy --prefix assets", "phx.digest"]
    ]
  end
end
