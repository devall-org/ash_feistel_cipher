defmodule AshFeistelCipher do
  defmodule Encrypt do
    defstruct [:source, :target, :bits, :key, :rounds, :__spark_metadata__]
  end

  @encrypt_schema [
    source: [
      type: :atom,
      required: true,
      doc: """
      Source attribute for feistel cipher. Can be any integer attribute.
      Use `integer_sequence` for an auto-generated bigserial column, or use any regular integer attribute.
      """
    ],
    target: [
      type: :atom,
      required: true,
      doc: """
      Target attribute for the encrypted value.
      Use `feistel_cipher_target` to automatically declare this attribute with the correct settings.
      """
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

  @integer_sequence %Spark.Dsl.Entity{
    name: :integer_sequence,
    describe: """
    Declares an auto-generated bigserial column.
    This is a convenience utility - you can also use any regular integer attribute (including nullable ones with `allow_nil?: true`) as a source for Feistel cipher encryption.
    """,
    examples: [
      "integer_sequence :seq",
      "integer_sequence :seq, allow_nil?: true"
    ],
    args: [:name],
    target: Ash.Resource.Attribute,
    schema:
      Ash.Resource.Attribute.attribute_schema()
      |> Spark.Options.Helpers.set_default!(:type, :integer)
      |> Spark.Options.Helpers.set_default!(:generated?, true),
    transform: {Ash.Resource.Attribute, :transform, []}
  }

  @integer_sequence_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @integer_sequence
  }

  def mark_as_feistel_target(attribute) do
    # First run the standard Ash attribute transform
    with {:ok, attribute} <- Ash.Resource.Attribute.transform(attribute) do
      # Then add our marker
      {:ok, Map.put(attribute, :__feistel_cipher_target__, true)}
    end
  end

  @feistel_cipher_target %Spark.Dsl.Entity{
    name: :feistel_cipher_target,
    describe: """
    Declares an encrypted integer column for Feistel cipher.
    This is a convenience utility that sets writable?: false and generated?: true automatically.
    """,
    examples: [
      "feistel_cipher_target :id, primary_key?: true",
      "feistel_cipher_target :referral_code",
      "feistel_cipher_target :optional_id, allow_nil?: true"
    ],
    args: [:name],
    target: Ash.Resource.Attribute,
    schema:
      Ash.Resource.Attribute.attribute_schema()
      |> Spark.Options.Helpers.set_default!(:writable?, false)
      |> Spark.Options.Helpers.set_default!(:generated?, true)
      |> Spark.Options.Helpers.set_default!(:type, :integer),
    transform: {__MODULE__, :mark_as_feistel_target, []}
  }

  @feistel_cipher_target_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @feistel_cipher_target
  }

  use Spark.Dsl.Extension,
    sections: [@feistel_cipher],
    dsl_patches: [@integer_sequence_patch, @feistel_cipher_target_patch],
    transformers: [AshFeistelCipher.Transformer]
end
