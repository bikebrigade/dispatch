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
        inherit (lib) optional;

        basePackages = [
          git
          libxml2
          openssl
          zlib
          curl
          libiconv
          docker-compose
          postgresql_16
        ] ++ optional stdenv.hostPlatform.isLinux inotify-tools;

        elixirPackages = [ beam.packages.erlang_29.elixir_1_20 ];

        nodePackages = [ nodejs yarn ];

        deployPackages = [ flyctl ];

        # Decorative prompt override so we know when we're in a dev shell
        baseHook = ''
          export PS1="\[\e[1;33m\][dev]\[\e[1;34m\] \w $ \[\e[0m\]"
        '';

        elixirHook = ''
          export MIX_HOME=$PWD/.nix-mix
          export HEX_HOME=$PWD/.nix-hex
          export PATH=$MIX_HOME/bin:$PATH
          export PATH=$HEX_HOME/bin:$PATH
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
