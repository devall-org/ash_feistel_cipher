defmodule AshFeistelCipher do
  defmodule Encrypt do
    defstruct [:source, :target, :bits, :rounds, :key, :__spark_metadata__]
  end

  @encrypt_schema [
    source: [
      type: :atom,
      required: true,
      doc: "Source attribute for feistel cipher"
    ],
    target: [
      type: :atom,
      required: true,
      doc: "Target attribute for feistel cipher"
    ],
    bits: [
      type: :integer,
      default: 52,
      doc: """
      The number of bits the source and target will use.
      Must be an even number less than or equal to 62. Cannot be changed after records are created.
      Default is 52 for JavaScript interoperability.
      """
    ],
    rounds: [
      type: :integer,
      default: 16,
      doc: """
      Number of Feistel rounds (1-32).
      More rounds = more secure but slower.
      Default is 16 for good security/performance balance.
      Cannot be changed after records are created.
      """
    ],
    key: [
      type: :integer,
      required: false,
      doc: """
      The encryption key to use for the Feistel cipher.
      If not provided, a key will be derived from the table name, source, target, and bits.
      Cannot be changed after records are created.
      You can generate a random key using FeistelCipher.random_key().
      """
    ]
  ]

  @encrypt %Spark.Dsl.Entity{
    name: :encrypt,
    describe: "Encrypts source attribute into target attribute with Feistel cipher.",
    examples: [
      """
      encrypt do
        source :seq
        target :id
        bits 40
      end
      """,
      """
      encrypt do
        source :seq
        target :id
        bits 40
        rounds 8
        key 12345
      end
      """
    ],
    target: AshFeistelCipher.Encrypt,
    schema: @encrypt_schema
  }

  @feistel_cipher %Spark.Dsl.Section{
    name: :feistel_cipher,
    describe: """
    Encrypts source attribute into target attribute with Feistel cipher.
    Can be used multiple times to encrypt multiple attributes.
    """,
    examples: [
      """
      feistel_cipher do
        functions_prefix "accounts"

        encrypt do
          source :seq
          target :id
          bits 40
          rounds 16
        end

        encrypt do
          source :seq
          target :referral_code
          rounds 8
          key 67890
        end
      end
      """
    ],
    schema: [
      functions_prefix: [
        type: :string,
        required: false,
        default: "public",
        doc:
          "PostgreSQL schema where feistel cipher functions are installed. Default is 'public' schema."
      ]
    ],
    entities: [@encrypt]
  }

  use Spark.Dsl.Extension,
    sections: [@feistel_cipher],
    transformers: [AshFeistelCipher.Transformer]
end
