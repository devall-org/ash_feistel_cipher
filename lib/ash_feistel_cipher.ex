defmodule AshFeistelCipher do
  defmodule FeistelEncrypted do
    @moduledoc false
    # Feistel-specific fields
    @feistel_fields [:from, :bits, :key, :rounds, :functions_prefix]
    # Ash.Resource.Attribute fields
    @ash_fields Ash.Resource.Attribute.attribute_schema() |> Keyword.keys()

    defstruct [:__spark_metadata__] ++ @feistel_fields ++ @ash_fields
  end

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
      |> Spark.Options.Helpers.set_default!(:generated?, true)
      |> Spark.Options.Helpers.set_default!(:allow_nil?, false),
    transform: {Ash.Resource.Attribute, :transform, []}
  }

  @integer_sequence_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @integer_sequence
  }

  def mark_as_feistel_encrypted(%FeistelEncrypted{} = feistel_attr) do
    # Extract feistel-specific options
    from = feistel_attr.from
    bits = feistel_attr.bits
    key = feistel_attr.key
    rounds = feistel_attr.rounds
    functions_prefix = feistel_attr.functions_prefix

    # Convert FeistelEncrypted struct to a map with Ash.Resource.Attribute fields
    ash_attr_map =
      feistel_attr
      |> Map.from_struct()
      |> Map.drop([:from, :bits, :key, :rounds, :functions_prefix])
      |> Map.update(:constraints, [], fn val -> val || [] end)

    # Run the standard Ash attribute transform
    with {:ok, attribute_map} <- Ash.Resource.Attribute.transform(ash_attr_map) do
      # Convert to struct and add our marker and store feistel options
      attribute_struct = struct!(Ash.Resource.Attribute, attribute_map)

      {:ok,
       attribute_struct
       |> Map.put(:__feistel_cipher_target__, true)
       |> Map.put(:__feistel_from__, from)
       |> Map.put(:__feistel_bits__, bits)
       |> Map.put(:__feistel_key__, key)
       |> Map.put(:__feistel_rounds__, rounds)
       |> Map.put(:__feistel_functions_prefix__, functions_prefix)}
    end
  end

  @feistel_encrypted_schema [
    from: [
      type: :atom,
      required: true,
      doc: "Source attribute for feistel cipher. Can be any integer attribute. Use `integer_sequence` for an auto-generated bigserial column, or use any regular integer attribute."
    ],
    bits: [
      type: :integer,
      default: 52,
      doc: "The number of bits the source and target will use. Must be an even number between 2 and 62. Cannot be changed after records are created. Default is 52 for JavaScript interoperability."
    ],
    key: [
      type: :integer,
      required: false,
      doc: "The encryption key to use for the Feistel cipher. Must be between 0 and 2^31-1 (2,147,483,647). If not provided, a key will be derived from the table name, source, target, and bits. Cannot be changed after records are created. You can generate a random key using FeistelCipher.random_key()."
    ],
    rounds: [
      type: :integer,
      default: 16,
      doc: "Number of Feistel rounds. Must be between 1 and 32. More rounds = more secure but slower. Default is 16 for good security/performance balance. Cannot be changed after records are created."
    ],
    functions_prefix: [
      type: :string,
      default: "public",
      doc: "PostgreSQL schema where feistel cipher functions are installed. Default is 'public' schema."
    ]
  ] ++ (Ash.Resource.Attribute.attribute_schema() |> Spark.Options.Helpers.set_default!(:writable?, false) |> Spark.Options.Helpers.set_default!(:generated?, true) |> Spark.Options.Helpers.set_default!(:type, :integer))

  @feistel_encrypted %Spark.Dsl.Entity{
    name: :feistel_encrypted,
    describe: """
    Declares an encrypted integer column for Feistel cipher.
    This is a convenience utility that sets writable?: false and generated?: true automatically.
    All encryption configuration is specified directly on the attribute.
    """,
    examples: [
      "feistel_encrypted :id, from: :seq, primary_key?: true",
      "feistel_encrypted :referral_code, from: :seq, key: 12345",
      "feistel_encrypted :optional_id, from: :seq, allow_nil?: true",
      "feistel_encrypted :id, from: :seq, bits: 40, functions_prefix: \"accounts\""
    ],
    args: [:name],
    target: AshFeistelCipher.FeistelEncrypted,
    schema: @feistel_encrypted_schema,
    transform: {__MODULE__, :mark_as_feistel_encrypted, []}
  }

  @feistel_encrypted_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @feistel_encrypted
  }

  use Spark.Dsl.Extension,
    dsl_patches: [@integer_sequence_patch, @feistel_encrypted_patch],
    transformers: [AshFeistelCipher.Transformer],
    verifiers: [
      AshFeistelCipher.Verifier.MissingSource,
      AshFeistelCipher.Verifier.AllowNilConsistency
    ]
end
