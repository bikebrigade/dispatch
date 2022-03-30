{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in with pkgs;
      let
        inherit (lib) optional optionals;

        basePackages = [
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

        elixirPackages = [ beam.packages.erlangR24.elixir_1_13 ];

        nodePackages = [ nodejs yarn ];

        deployPackages = [ flyctl ];

        # Decorative prompt override so we know when we're in a dev shell
        baseHook = ''
          export PS1='\n\[\033[1;32m\][dev:\w]($(git rev-parse --abbrev-ref HEAD))\$\[\033[0m\] '

          [[ -f .env ]] && source .env
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
