defmodule AshFeistelCipher do
  defmodule Encrypt do
    defstruct [:source, :target, :bits, :key]
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
      Must be an even number less than or equal to 62. Cannot be changed after table creation.
      Default is 52 for JavaScript interoperability.
      """
    ],
    key: [
      type: :integer,
      required: false,
      doc: """
      The encryption key to use for the Feistel cipher.
      If not provided, a key will be derived from the table name, source, target, and bits.
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
        prefix "accounts"

        encrypt do
          source :seq
          target :id
          bits 40
        end

        encrypt do
          source :seq
          target :referrer_code
          key 67890
        end
      end
      """
    ],
    schema: [
      prefix: [
        type: :string,
        required: false,
        default: "public",
        doc: "PostgreSQL schema where feistel cipher functions are installed. Default is 'public' schema."
      ]
    ],
    entities: [@encrypt]
  }

  use Spark.Dsl.Extension,
    sections: [@feistel_cipher],
    transformers: [AshFeistelCipher.Transformer]
end
