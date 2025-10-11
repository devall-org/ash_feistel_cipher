spark_locals_without_parens = [
  bits: 1,
  encrypt: 1,
  feistel_cipher_source: 1,
  functions_prefix: 1,
  key: 1,
  rounds: 1,
  source: 1,
  target: 1
]

[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
