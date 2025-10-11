defmodule AshFeistelCipher.Verifier.MissingSource do
  @moduledoc """
  Verifies that all `feistel_encrypted` attributes have a `from` configured.
  """
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  @impl true
  def verify(dsl_state) do
    # Get all attributes
    attributes = Verifier.get_entities(dsl_state, [:attributes])

    # Find attributes defined with feistel_encrypted
    # These have the __feistel_cipher_target__ marker
    feistel_targets =
      attributes
      |> Enum.filter(fn attr ->
        Map.get(attr, :__feistel_cipher_target__, false)
      end)

    # Find feistel_encrypted that don't have a from
    missing_from =
      feistel_targets
      |> Enum.filter(fn attr ->
        is_nil(Map.get(attr, :__feistel_from__))
      end)
      |> Enum.map(& &1.name)

    if missing_from != [] do
      {:error,
       Spark.Error.DslError.exception(
         module: Verifier.get_persisted(dsl_state, :module),
         message: """
         The following attributes are declared as `feistel_encrypted` but have no `from` configured:
         #{Enum.map_join(missing_from, ", ", &inspect/1)}

         Please specify a from attribute:

             feistel_encrypted :#{List.first(missing_from) || "attribute"}, from: :seq

         Or use `attribute` instead of `feistel_encrypted` if encryption is not needed.
         """,
         path: [:attributes]
       )}
    else
      :ok
    end
  end
end
