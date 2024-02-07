[
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,apps,test}/**/*.{heex,ex,exs}",
    "priv/repo/seeds/*.exs"
  ],
  subdirectories: ["priv/*/migrations"],
  line_length: 120
]
