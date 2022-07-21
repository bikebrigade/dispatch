{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, flake-compat }:
    utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in with pkgs;
      let
        inherit (lib) optional optionals;

        basePackages = [
          chromedriver
          git
          libxml2
          openssl
          zlib
          curl
          libiconv
          docker-compose
          postgresql_13
        ] ++ optional stdenv.isLinux inotify-tools ++ optionals stdenv.isDarwin
          (with darwin.apple_sdk.frameworks; [
            # For file_system on macOS.
            CoreFoundation
            CoreServices
          ]);

        elixirPackages = [ beam.packages.erlangR25.elixir_1_13 ];

        nodePackages = [ nodejs yarn ];

        deployPackages = [ flyctl ];

        # Decorative prompt override so we know when we're in a dev shell
        baseHook = ''
          export PS1="\[\e[1;33m\][dev]\[\e[1;34m\] \w $ \[\e[0m\]"

          set -a
          [[ -f .env.local ]] && . .env.local
          set +a

        '';

        elixirHook = ''
          export ERL_AFLAGS="-kernel shell_history enabled"
          export ERL_LIBS="" # see https://elixirforum.com/t/compilation-warnings-clause-cannot-match-in-mix-and-otp-tutorial/25114/4
        '';

        nodeHook = ''
          export NODE_BIN=$PWD/assets/node_modules/.bin
          export PATH=$NODE_BIN:$PATH
        '';

      in {
        devShell = with pkgs;
          mkShell {
            buildInputs = basePackages ++ elixirPackages ++ nodePackages
              ++ deployPackages;

            shellHook = baseHook + elixirHook + nodeHook;
          };

      });
}
