defmodule AshFeistelCipher.Transformer do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Ash.Resource.Attribute

  @impl Spark.Dsl.Transformer
  def before?(_), do: true

  @impl Spark.Dsl.Transformer
  def transform(dsl_state) do
    prefix = Transformer.get_option(dsl_state, [:feistel_cipher], :prefix)

    dsl_state
    |> tap(&validate_unique_target!/1)
    |> Transformer.get_entities([:feistel_cipher])
    |> Enum.reduce(dsl_state, &add_feistel_cipher_trigger(&1, &2, prefix))
    |> then(fn dsl_state -> {:ok, dsl_state} end)
  end

  defp validate_unique_target!(dsl_state) do
    dsl_state
    |> Transformer.get_entities([:feistel_cipher])
    |> Enum.group_by(fn entity -> entity.target end)
    |> Enum.each(fn {target, encrypts} ->
      if length(encrypts) > 1 do
        raise "#{target} is used for multiple encrypts: #{inspect(encrypts)}"
      end
    end)
  end

  defp add_feistel_cipher_trigger(
         %AshFeistelCipher.Encrypt{
           source: source,
           target: target,
           bits: bits,
           key: key
         },
         dsl_state,
         prefix
       ) do
    source = get_db_column_name(source, dsl_state)
    target = get_db_column_name(target, dsl_state)

    table = dsl_state |> Transformer.get_option([:postgres], :table)
    up = FeistelCipher.Migration.up_for_encryption(table, source, target, bits: bits, key: key, prefix: prefix)
    down = FeistelCipher.Migration.down_for_encryption(table, source, target, prefix: prefix)

    {:ok, statement} =
      Transformer.build_entity(
        AshPostgres.DataLayer,
        [:postgres, :custom_statements],
        :statement,
        name: :feistel_cipher,
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
