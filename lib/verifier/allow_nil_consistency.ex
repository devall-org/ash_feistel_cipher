defmodule AshFeistelCipher.Verifier.AllowNilConsistency do
  @moduledoc """
  Verifies that when a source attribute allows nil, the target attribute also allows nil.

  This prevents potential errors where a nullable source value cannot be stored in a non-nullable target.
  """
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  @impl true
  def verify(dsl_state) do
    # Get all attributes
    attributes = Verifier.get_entities(dsl_state, [:attributes])

    # Create a map of attribute names to their allow_nil? setting
    attr_map = Map.new(attributes, fn attr -> {attr.name, Map.get(attr, :allow_nil?, false)} end)

    # Find encrypted_integer attributes
    feistel_targets =
      attributes
      |> Enum.filter(fn attr ->
        Map.get(attr, :__feistel_cipher_target__, false)
      end)

    # Check each encrypted_integer attribute
    inconsistent =
      Enum.filter(feistel_targets, fn target_attr ->
        source_name = Map.get(target_attr, :__feistel_from__)
        source_allow_nil = Map.get(attr_map, source_name, false)
        target_allow_nil = Map.get(target_attr, :allow_nil?, false)

        # If source allows nil, target should also allow nil
        source_allow_nil && !target_allow_nil
      end)

    case inconsistent do
      [] ->
        :ok

      attrs_with_issues ->
        error_details =
          Enum.map_join(attrs_with_issues, "\n", fn attr ->
            source_name = Map.get(attr, :__feistel_from__)
            "  - from: #{inspect(source_name)} (allow_nil?: true), target: #{inspect(attr.name)} (allow_nil?: false)"
          end)

        {:error,
         Spark.Error.DslError.exception(
           module: Verifier.get_persisted(dsl_state, :module),
           message: """
           Nullable column mismatch detected. When a source attribute allows nil, the target attribute should also allow nil:

           #{error_details}

           Please update the target attribute(s) to include `allow_nil?: true`:

               encrypted_integer :#{List.first(attrs_with_issues).name}, from: :#{Map.get(List.first(attrs_with_issues), :__feistel_from__)}, allow_nil?: true
           """,
           path: [:attributes]
         )}
    end
  end
end
