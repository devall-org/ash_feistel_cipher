defmodule AshFeistelCipher.Transformer do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Ash.Resource.Attribute

  @impl Spark.Dsl.Transformer
  def before?(_), do: true

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    dsl_state
    |> get_feistel_encrypted_attributes()
    |> Enum.reduce(dsl_state, &add_feistel_cipher_trigger(&1, &2))
    |> then(fn dsl_state -> {:ok, dsl_state} end)
  end

  defp get_feistel_encrypted_attributes(dsl_state) do
    dsl_state
    |> Transformer.get_entities([:attributes])
    |> Enum.filter(fn attr ->
      Map.get(attr, :__feistel_cipher_target__, false)
    end)
  end

  defp add_feistel_cipher_trigger(attribute, dsl_state) do
    source_attr = Map.get(attribute, :__feistel_from__)
    target_attr = attribute.name
    bits = Map.get(attribute, :__feistel_bits__)
    key = Map.get(attribute, :__feistel_key__)
    rounds = Map.get(attribute, :__feistel_rounds__)
    functions_prefix = Map.get(attribute, :__feistel_functions_prefix__)

    source = get_db_column_name(source_attr, dsl_state)
    target = get_db_column_name(target_attr, dsl_state)

    table = dsl_state |> Transformer.get_option([:postgres], :table)
    prefix = dsl_state |> Transformer.get_option([:postgres], :schema) || "public"

    # Apply defaults at compile time
    bits = bits || 52
    rounds = rounds || 16
    functions_prefix = functions_prefix || "public"
    key = key || FeistelCipher.generate_key(prefix, table, source, target)

    up = """
    execute(
      FeistelCipher.up_for_trigger(#{inspect(prefix)}, #{inspect(table)}, #{inspect(source)}, #{inspect(target)},
        bits: #{bits},
        key: #{key},
        rounds: #{rounds},
        functions_prefix: #{inspect(functions_prefix)}
      )
    )
    """

    down = """
    execute(
      FeistelCipher.down_for_trigger(#{inspect(prefix)}, #{inspect(table)}, #{inspect(source)}, #{inspect(target)})
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
end
