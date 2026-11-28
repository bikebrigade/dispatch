{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, devshell, flake-compat }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
        inherit (pkgs) lib;

        # Libraries native dependencies may compile or link against
        nativeLibraries = with pkgs; [ libxml2 openssl zlib libiconv ];

        # Menu entry that runs one of the scripts in scripts/
        script = category: name: file: help: {
          inherit category name help;
          command = ''"$PRJ_ROOT/scripts/${file}" "$@"'';
        };
        dev = script "development";
        ops = script "operations";

      in {
        devShells.default = pkgs.devshell.mkShell {
          name = "dispatch";

          # devshell has no stdenv, so the C toolchain for NIFs is set up here
          packages = with pkgs;
            [ git curl gnumake stdenv.cc pkg-config nodejs yarn ]
            ++ map lib.getLib nativeLibraries ++ map lib.getDev nativeLibraries
            ++ lib.optional stdenv.hostPlatform.isLinux inotify-tools;

          env = [
            {
              name = "LIBRARY_PATH";
              prefix = "$DEVSHELL_DIR/lib";
            }
            {
              name = "C_INCLUDE_PATH";
              prefix = "$DEVSHELL_DIR/include";
            }
            {
              name = "PKG_CONFIG_PATH";
              prefix = "$DEVSHELL_DIR/lib/pkgconfig";
            }
            {
              name = "PKG_CONFIG_PATH";
              prefix = "$DEVSHELL_DIR/share/pkgconfig";
            }
            {
              name = "MIX_HOME";
              eval = "$PRJ_ROOT/.nix-mix";
            }
            {
              name = "HEX_HOME";
              eval = "$PRJ_ROOT/.nix-hex";
            }
            {
              name = "PATH";
              prefix = "$PRJ_ROOT/.nix-mix/bin";
            }
            {
              name = "PATH";
              prefix = "$PRJ_ROOT/.nix-hex/bin";
            }
            {
              name = "PATH";
              prefix = "$PRJ_ROOT/assets/node_modules/.bin";
            }
            {
              name = "ERL_AFLAGS";
              value = "-kernel shell_history enabled";
            }
            {
              # see https://elixirforum.com/t/compilation-warnings-clause-cannot-match-in-mix-and-otp-tutorial/25114/4
              name = "ERL_LIBS";
              value = "";
            }
          ];

          commands = [
            (dev "server" "server" "Start the Phoenix server with an IEx console")
            (dev "tests" "test" "Run the tests (optionally path/to/test.exs:LINE)")
            (dev "fmt" "format" "Format the code")
            (dev "lint-ui" "lint_ui" "List hard-coded palette colours in templates")
            {
              category = "development";
              name = "db-up";
              help = "Start Postgres in Docker";
              command = ''docker-compose -f "$PRJ_ROOT/docker-compose.yml" up -d "$@"'';
            }
            (ops "logs" "logs" "Tail Fly logs: logs <prod|staging>")
            (ops "remote-console" "remote_console" "SSH into a Fly machine: remote-console <prod|staging>")
            (ops "observer" "observer" "Attach a local Observer to the Fly app (needs RELEASE_COOKIE)")
            (ops "deploy-staging" "deploy_staging" "Force-push HEAD to the staging branch")
            (ops "restore-staging-db" "restore_staging_db" "Replace the staging database with a copy of prod (destructive)")
            {
              category = "languages";
              package = pkgs.beam.packages.erlang_29.elixir_1_20;
            }
            {
              category = "tools";
              package = pkgs.docker-compose;
            }
            {
              category = "tools";
              name = "psql";
              package = pkgs.postgresql_16;
            }
            {
              category = "operations";
              package = pkgs.flyctl;
            }
            {
              category = "operations";
              name = "gcloud";
              package = pkgs.google-cloud-sdk;
            }
            {
              category = "operations";
              name = "cloud-sql-proxy";
              help = "Tunnel to Cloud SQL with your Google login (used by restore-staging-db)";
              package = pkgs.google-cloud-sql-proxy;
            }
            {
              category = "tools";
              package = pkgs.jq;
            }
          ];
        };
      });
}
