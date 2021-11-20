wrap_nix_shell () {
  command="$1"
  if [ "$IN_NIX_SHELL" == "" ]; then
    nix-shell --run "$command"
  else
    $command
  fi
}