spark_locals_without_parens = [
  encrypted_integer: 2,
  encrypted_integer_primary_key: 2,
  integer_sequence: 1,
  integer_sequence: 2
]

[
  import_deps: [:ash, :ash_postgres, :spark],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
