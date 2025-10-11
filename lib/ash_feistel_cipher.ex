defmodule AshFeistelCipher do
  defmodule Encrypt do
    defstruct [:source, :target, :bits, :key, :rounds, :__spark_metadata__]
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
    key: [
      type: :integer,
      required: false,
      doc: """
      The encryption key to use for the Feistel cipher.
      If not provided, a key will be derived from the table name, source, target, and bits.
      Cannot be changed after records are created.
      You can generate a random key using FeistelCipher.random_key().
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
        rounds 8
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
        end

        encrypt do
          source :seq
          target :referral_code
          key 67890
          rounds 8
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

  @feistel_cipher_source %Spark.Dsl.Entity{
    name: :feistel_cipher_source,
    describe: "Declares an auto-generated integer sequence column for Feistel cipher encryption.",
    examples: ["feistel_cipher_source :seq"],
    args: [:name],
    target: Ash.Resource.Attribute,
    schema:
      Ash.Resource.Attribute.integer_primary_key_schema()
      |> Spark.Options.Helpers.set_default!(:primary_key?, false)
      |> Spark.Options.Helpers.set_default!(:public?, false),
    auto_set_fields: [allow_nil?: false],
    transform: {Ash.Resource.Attribute, :transform, []}
  }

  @feistel_cipher_source_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @feistel_cipher_source
  }

  use Spark.Dsl.Extension,
    sections: [@feistel_cipher],
    dsl_patches: [@feistel_cipher_source_patch],
    transformers: [AshFeistelCipher.Transformer]
end
