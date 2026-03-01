defmodule AshFeistelCipher.Transformer do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Ash.Resource.Attribute

  @impl Spark.Dsl.Transformer
  def before?(_), do: true

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    dsl_state
    |> get_feistel_cipher_attributes()
    |> Enum.reduce(dsl_state, &add_feistel_cipher_trigger(&1, &2))
    |> then(fn dsl_state -> {:ok, dsl_state} end)
  end

  defp get_feistel_cipher_attributes(dsl_state) do
    dsl_state
    |> Transformer.get_entities([:attributes])
    |> Enum.filter(fn attr ->
      Map.has_key?(attr, :__feistel_cipher__)
    end)
  end

  defp add_feistel_cipher_trigger(attribute, dsl_state) do
    opts =
      AshFeistelCipher.feistel_default_options()
      |> Map.merge(Map.get(attribute, :__feistel_cipher__, %{}), fn _key, default, value ->
        if is_nil(value), do: default, else: value
      end)

    from_attr = opts.from
    to_attr = attribute.name
    time_bits = opts.time_bits
    time_bucket = opts.time_bucket
    time_offset = opts.time_offset
    encrypt_time = opts.encrypt_time
    data_bits = opts.data_bits
    key = opts.key
    rounds = opts.rounds
    functions_prefix = opts.functions_prefix

    from_column = get_db_column_name(from_attr, dsl_state)
    to_column = get_db_column_name(to_attr, dsl_state)

    table = dsl_state |> Transformer.get_option([:postgres], :table)
    prefix = dsl_state |> Transformer.get_option([:postgres], :schema, "public")

    key = key || FeistelCipher.generate_key(prefix, table, from_column, to_column)

    # Format key with underscores for readability
    key_formatted = format_number_with_underscores(key)

    up = """
    execute(
      FeistelCipher.up_for_v1_trigger(#{inspect(prefix)}, #{inspect(table)}, #{inspect(from_column)}, #{inspect(to_column)},
        time_bits: #{time_bits},
        time_bucket: #{time_bucket},
        time_offset: #{time_offset},
        encrypt_time: #{encrypt_time},
        data_bits: #{data_bits},
        key: #{key_formatted},
        rounds: #{rounds},
        functions_prefix: #{inspect(functions_prefix)}
      )
    )
    """

    down = """
    execute(
      FeistelCipher.down_for_v1_trigger(#{inspect(prefix)}, #{inspect(table)}, #{inspect(from_column)}, #{inspect(to_column)})
    )
    """

    {:ok, statement} =
      Transformer.build_entity(
        AshPostgres.DataLayer,
        [:postgres, :custom_statements],
        :statement,
        name: :feistel_cipher,
        code?: true,
        up: up,
        down: down
      )

    dsl_state |> Transformer.add_entity([:postgres, :custom_statements], statement, type: :append)
  end

  defp get_db_column_name(attr_name, dsl_state) do
    %Attribute{source: db_column_name} =
      dsl_state |> Transformer.get_entities([:attributes]) |> Enum.find(&(&1.name == attr_name))

    db_column_name
  end

  defp format_number_with_underscores(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join("_")
    |> String.reverse()
  end
end
