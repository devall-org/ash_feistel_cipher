spark_locals_without_parens = [
  bits: 1,
  encrypt: 1,
  functions_prefix: 1,
  key: 1,
  source: 1,
  target: 1
]

[
  import_deps: [:spark, :reactor, :ash],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Spark.Formatter],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
