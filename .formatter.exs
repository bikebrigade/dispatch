[
  import_deps: [:ecto, :phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{ex,exs,heex}", "{config,lib,test}/**/*.{ex,exs,heex}"],
  subdirectories: ["priv/repo/"]
]
