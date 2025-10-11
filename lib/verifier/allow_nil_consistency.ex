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

    # Get encrypt configurations (entities are directly under [:feistel_cipher])
    encrypts = Verifier.get_entities(dsl_state, [:feistel_cipher])

    # Create a map of attribute names to their allow_nil? setting
    attr_map = Map.new(attributes, fn attr -> {attr.name, Map.get(attr, :allow_nil?, false)} end)

    # Check each encrypt configuration
    inconsistent =
      Enum.filter(encrypts, fn encrypt ->
        source_allow_nil = Map.get(attr_map, encrypt.source, false)
        target_allow_nil = Map.get(attr_map, encrypt.target, false)

        # If source allows nil, target should also allow nil
        source_allow_nil && !target_allow_nil
      end)

    case inconsistent do
      [] ->
        :ok

      encrypts_with_issues ->
        error_details =
          Enum.map_join(encrypts_with_issues, "\n", fn encrypt ->
            "  - source: #{inspect(encrypt.source)} (allow_nil?: true), target: #{inspect(encrypt.target)} (allow_nil?: false)"
          end)

        {:error,
         Spark.Error.DslError.exception(
           module: Verifier.get_persisted(dsl_state, :module),
           message: """
           Nullable column mismatch detected. When a source attribute allows nil, the target attribute should also allow nil:

           #{error_details}

           Please update the target attribute(s) to include `allow_nil? true`:

               feistel_cipher_target :#{List.first(encrypts_with_issues).target}, :string do
                 allow_nil? true
               end
           """,
           path: [:feistel_cipher]
         )}
    end
  end
end
