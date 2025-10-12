defmodule AshFeistelCipher.Verifier.MissingSource do
  @moduledoc """
  Verifies that all `encrypted_integer` attributes have a `from` configured.
  """
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  @impl true
  def verify(dsl_state) do
    # Get all attributes
    attributes = Verifier.get_entities(dsl_state, [:attributes])

    # Find attributes defined with encrypted_integer
    # These have the __feistel_encrypted__ marker
    encrypted_attrs =
      attributes
      |> Enum.filter(fn attr ->
        Map.get(attr, :__feistel_encrypted__, false)
      end)

    # Find encrypted_integer that don't have a from
    missing_from =
      encrypted_attrs
      |> Enum.filter(fn attr ->
        is_nil(Map.get(attr, :__feistel_from__))
      end)
      |> Enum.map(& &1.name)

    if missing_from != [] do
      {:error,
       Spark.Error.DslError.exception(
         module: Verifier.get_persisted(dsl_state, :module),
         message: """
         The following attributes are declared as `encrypted_integer` but have no `from` configured:
         #{Enum.map_join(missing_from, ", ", &inspect/1)}

         Please specify a from attribute:

             encrypted_integer :#{List.first(missing_from) || "attribute"}, from: :seq

         Or use `attribute` instead of `encrypted_integer` if encryption is not needed.
         """,
         path: [:attributes]
       )}
    else
      :ok
    end
  end
end
