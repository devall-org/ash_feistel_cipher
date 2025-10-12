defmodule AshFeistelCipher.Verifier.AllowNilConsistency do
  @moduledoc """
  Verifies that when a from attribute allows nil, the encrypted attribute also allows nil.

  This prevents potential errors where a nullable from value cannot be stored in a non-nullable encrypted attribute.
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
    encrypted_attrs =
      attributes
      |> Enum.filter(fn attr ->
        Map.get(attr, :__feistel_encrypted__, false)
      end)

    # Check each encrypted_integer attribute
    inconsistent =
      Enum.filter(encrypted_attrs, fn encrypted_attr ->
        from_name = Map.get(encrypted_attr, :__feistel_from__)
        from_allow_nil = Map.get(attr_map, from_name, false)
        encrypted_allow_nil = Map.get(encrypted_attr, :allow_nil?, false)

        # If from attribute allows nil, encrypted attribute should also allow nil
        from_allow_nil && !encrypted_allow_nil
      end)

    case inconsistent do
      [] ->
        :ok

      attrs_with_issues ->
        error_details =
          Enum.map_join(attrs_with_issues, "\n", fn attr ->
            from_name = Map.get(attr, :__feistel_from__)

            "  - from: #{inspect(from_name)} (allow_nil?: true), encrypted: #{inspect(attr.name)} (allow_nil?: false)"
          end)

        {:error,
         Spark.Error.DslError.exception(
           module: Verifier.get_persisted(dsl_state, :module),
           message: """
           Nullable column mismatch detected. When a from attribute allows nil, the encrypted attribute should also allow nil:

           #{error_details}

           Please update the encrypted attribute(s) to include `allow_nil?: true`:

               encrypted_integer :#{List.first(attrs_with_issues).name}, from: :#{Map.get(List.first(attrs_with_issues), :__feistel_from__)}, allow_nil?: true
           """,
           path: [:attributes]
         )}
    end
  end
end
