{ sources ? import ./nix/sources.nix { }, pkgs ? import sources.nixpkgs { } }:
with pkgs;
let
  inherit (lib) optional optionals;

  basePackages =
    [ git libxml2 openssl zlib curl libiconv docker-compose postgresql_12 ]
    ++ optional stdenv.isLinux inotify-tools ++ optionals stdenv.isDarwin
    (with darwin.apple_sdk.frameworks; [
      # For file_system on macOS.
      CoreFoundation
      CoreServices
    ]);

  elixirPackages = [ beam.packages.erlangR24.elixir_1_13 ];

  nodePackages = [ nodejs yarn ];

  deployPackages = [ flyctl ];

  inputs = basePackages ++ elixirPackages ++ nodePackages ++ deployPackages;

  localPath = ./. + "/local.nix";

  final = if builtins.pathExists localPath then
    inputs ++ (import localPath)
  else
    inputs;

  chromeCommand = if stdenv.isDarwin then "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" else "google-chrome";
  # define shell startup command with special handling for OSX
  baseHooks = ''
    export PS1='\n\[\033[1;32m\][nix-shell:\w]($(git rev-parse --abbrev-ref HEAD))\$\[\033[0m\] '
    export LANG=en_US.UTF-8

    # install chromedriver for Wallaby
    ./scripts/download_chromedriver "${chromeCommand}"

    if test -f ".env.local"
    then
      set -a
      source .env.local
      set +a
    fi
  '';

  elixirHooks = ''
    export ERL_AFLAGS="-kernel shell_history enabled"
    export ERL_LIBS="" # see https://elixirforum.com/t/compilation-warnings-clause-cannot-match-in-mix-and-otp-tutorial/25114/4
  '';

  nodeHooks = ''
    export NODE_BIN=$PWD/assets/node_modules/.bin
    export PATH=$NODE_BIN:$PATH
  '';

  hooks = baseHooks + elixirHooks + nodeHooks;
in pkgs.mkShell {
  buildInputs = final;
  shellHook = hooks;
}
