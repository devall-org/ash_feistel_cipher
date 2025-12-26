defmodule AshFeistelCipher do
  defmodule EncryptedIntegerAttribute do
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
    This is a convenience utility - you can also use any regular integer attribute (including nullable ones with `allow_nil?: true`) with the `from` option for Feistel cipher encryption.
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
      |> Spark.Options.Helpers.set_default!(:writable?, false)
      |> Spark.Options.Helpers.set_default!(:generated?, true)
      |> Spark.Options.Helpers.set_default!(:allow_nil?, false),
    transform: {Ash.Resource.Attribute, :transform, []}
  }

  @integer_sequence_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @integer_sequence
  }

  def transform(%EncryptedIntegerAttribute{} = entity) do
    # Extract feistel-specific options
    from = entity.from
    bits = entity.bits
    key = entity.key
    rounds = entity.rounds
    functions_prefix = entity.functions_prefix

    # Convert EncryptedIntegerAttribute struct to a map with Ash.Resource.Attribute fields
    ash_attr_map =
      entity
      |> Map.from_struct()
      |> Map.drop([:from, :bits, :key, :rounds, :functions_prefix])
      |> Map.update(:constraints, [], fn val -> val || [] end)

    # Run the standard Ash attribute transform
    with {:ok, attribute_map} <- Ash.Resource.Attribute.transform(ash_attr_map) do
      # Convert to struct and add our marker and store feistel options
      attribute_struct = struct!(Ash.Resource.Attribute, attribute_map)

      {:ok,
       attribute_struct
       |> Map.put(:__feistel_cipher__, %{
         from: from,
         bits: bits,
         key: key,
         rounds: rounds,
         functions_prefix: functions_prefix
       })}
    end
  end

  # Common Feistel cipher options shared by all encrypted integer types
  @feistel_options [
    from: [
      type: :atom,
      required: true,
      doc:
        "Integer attribute to encrypt. Can be any integer attribute. Use `integer_sequence` for an auto-generated bigserial column, or use any regular integer attribute."
    ],
    bits: [
      type: :integer,
      default: 52,
      doc:
        "The number of bits for encryption. Must be an even number between 2 and 62. Cannot be changed after records are created. Default is 52 for JavaScript interoperability."
    ],
    key: [
      type: :integer,
      required: false,
      doc:
        "The encryption key to use for the Feistel cipher. Must be between 0 and 2^31-1 (2,147,483,647). If not provided, a key will be derived from the table name, column names, and bits. Cannot be changed after records are created."
    ],
    rounds: [
      type: :integer,
      default: 16,
      doc:
        "Number of Feistel rounds. Must be between 1 and 32. More rounds = more secure but slower. Default is 16 for good security/performance balance. Cannot be changed after records are created."
    ],
    functions_prefix: [
      type: :string,
      default: "public",
      doc:
        "PostgreSQL schema where feistel cipher functions are installed. Default is 'public' schema."
    ]
  ]

  @encrypted_integer %Spark.Dsl.Entity{
    name: :encrypted_integer,
    describe: """
    Declares an encrypted integer column for Feistel cipher.
    This is a convenience utility that sets writable?: false and generated?: true automatically.
    All encryption configuration is specified directly on the attribute.
    """,
    examples: [
      "encrypted_integer :id, from: :seq, primary_key?: true",
      "encrypted_integer :referral_code, from: :seq, key: 12345",
      "encrypted_integer :optional_id, from: :seq, allow_nil?: true",
      "encrypted_integer :id, from: :seq, bits: 40, functions_prefix: \"accounts\""
    ],
    args: [:name],
    target: AshFeistelCipher.EncryptedIntegerAttribute,
    schema:
      @feistel_options ++
        (Ash.Resource.Attribute.attribute_schema()
         |> Spark.Options.Helpers.set_default!(:type, :integer)
         |> Spark.Options.Helpers.set_default!(:writable?, false)
         |> Spark.Options.Helpers.set_default!(:generated?, true)),
    transform: {__MODULE__, :transform, []}
  }

  @encrypted_integer_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @encrypted_integer
  }

  @encrypted_integer_primary_key %Spark.Dsl.Entity{
    name: :encrypted_integer_primary_key,
    describe: """
    Declares an encrypted integer primary key column for Feistel cipher.
    This is a convenience utility that sets primary_key?: true, allow_nil?: false, public?: true, writable?: false, and generated?: true automatically.
    All encryption configuration is specified directly on the attribute.
    """,
    examples: [
      "encrypted_integer_primary_key :id, from: :seq",
      "encrypted_integer_primary_key :id, from: :seq, bits: 40",
      "encrypted_integer_primary_key :id, from: :seq, key: 12345, rounds: 8"
    ],
    args: [:name],
    target: AshFeistelCipher.EncryptedIntegerAttribute,
    schema:
      @feistel_options ++
        (Ash.Resource.Attribute.attribute_schema()
         |> Spark.Options.Helpers.set_default!(:type, :integer)
         |> Spark.Options.Helpers.set_default!(:writable?, false)
         |> Spark.Options.Helpers.set_default!(:generated?, true)
         |> Spark.Options.Helpers.set_default!(:primary_key?, true)
         |> Spark.Options.Helpers.set_default!(:allow_nil?, false)
         |> Spark.Options.Helpers.set_default!(:public?, true)),
    transform: {__MODULE__, :transform, []}
  }

  @encrypted_integer_primary_key_patch %Spark.Dsl.Patch.AddEntity{
    section_path: [:attributes],
    entity: @encrypted_integer_primary_key
  }

  use Spark.Dsl.Extension,
    dsl_patches: [
      @integer_sequence_patch,
      @encrypted_integer_patch,
      @encrypted_integer_primary_key_patch
    ],
    transformers: [AshFeistelCipher.Transformer],
    verifiers: [
      AshFeistelCipher.Verifier.MissingSource,
      AshFeistelCipher.Verifier.AllowNilConsistency
    ]
end
