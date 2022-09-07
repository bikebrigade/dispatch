defmodule BikeBrigade.MixProject do
  use Mix.Project

  def project do
    [
      app: :bike_brigade,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    extras =
      case Mix.env() do
        :test -> []
        _ -> [:os_mon]
      end

    [
      mod: {BikeBrigade.Application, []},
      extra_applications: [:logger, :runtime_tools, :honeybadger] ++ extras
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "priv/repo"]
  defp elixirc_paths(:dev), do: ["lib", "priv/repo"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.5"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.7"},
      {:ecto_psql_extras, "~> 0.7.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.17.9"},
      {:floki, ">= 0.0.0", only: :test},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6.2"},
      {:reverse_proxy_plug, "~> 2.1.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 1.0.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:httpoison, "~> 1.6"},
      {:nimble_csv, "~> 1.2.0"},
      {:ex_phone_number, "~> 0.2"},
      {:ecto_enum, "~> 1.4"},
      {:geo_postgis, "~> 3.4.0"},
      {:lib_lat_lon, "~> 0.4"},
      # required by lib_lat_lon
      {:nextexif, "~> 0.0"},
      {:topo, "~> 0.4.0"},
      {:ex_twilio, "~> 0.9.1"},
      {:mailchimp, "~> 0.1.2"},
      {:google_api_drive, "~> 0.24.0"},
      {:google_api_storage, "~> 0.32.1"},
      {:google_api_sheets, "~> 0.29.0"},
      {:goth, "~> 1.3-rc", override: true},
      {:faker, "~> 0.17"},
      {:mustache, "~> 0.4.0"},
      {:honeybadger, "~> 0.18.1"},
      {:recase, "~> 0.5"},
      {:heroicons, "~> 0.4.1"},
      {:linkify,
       git: "https://github.com/mveytsman/linkify",
       ref: "42c1aca5da2c2ab28abf8f304b211c2a5d2c89c7"},
      {:crontab, "~> 1.1.10"},
      {:tzdata, "~> 1.1"},
      {:benchee, "~> 1.0.1"},
      {:prom_ex, "~> 1.6.0"},
      {:esbuild, "~> 0.4.0", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:wallaby, "~> 0.29.1", runtime: false, only: :test},
      {:libcluster, "~> 3.3"},
      {:horde, "~> 0.8.6"},
      {:inflex, "~> 2.0.0"},

      # LiveBook Stuff
      {:kino, "~> 0.4.1"},
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
      "bb.init": [
        &copy_env/1,
        "local.hex --force --if-missing",
        "local.rebar --force --if-missing",
        "setup"
      ],
      setup: [
        "deps.get",
        "ecto.setup",
        "cmd mix ecto.migrate --migrations-path priv/repo/data_migrations",
        "cmd npm install --prefix assets"
      ],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "assets.deploy": ["esbuild default --minify", "tailwind default --minify", "phx.digest"]
    ]
  end

  defp copy_env(_) do
    unless File.exists?(".env.local") do
      File.copy!(".env.local.sample", ".env.local")
    end
  end
end
