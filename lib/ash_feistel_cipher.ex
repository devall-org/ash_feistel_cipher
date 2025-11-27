defmodule AshFeistelCipher do
  defmodule Encrypt do
    defstruct [:__spark_metadata__, :source, :target, :bits, :bits_confirm]
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
    bits_confirm: [
      type: :string,
      default: "0x34",
      doc: """
      A string representation of bits in hexadecimal.
      Example: bits 40 -> bits_confirm "0x28".
      Since bits must not be changed after table creation,
      bits_confirm is required to prevent errors if bits are changed by mistake,
      for example, through find and replace.
      Default is "0x34" for JavaScript interoperability.
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
        bits_confirm "0x28"
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
        encrypt do
          source :seq
          target :id
          bits 40
          bits_confirm "0x28"
        end

        encrypt do
          source :other_source
          target :other_target
        end
      end
      """
    ],
    schema: [],
    entities: [@encrypt]
  }

  use Spark.Dsl.Extension,
    sections: [@feistel_cipher],
    transformers: [AshFeistelCipher.Transformer]
end
