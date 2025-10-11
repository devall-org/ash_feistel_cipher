defmodule AshFeistelCipher.Verifier.MissingEncrypt do
  @moduledoc """
  Verifies that all `feistel_cipher_target` attributes have corresponding `encrypt` configurations.
  """
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier

  @impl true
  def verify(dsl_state) do
    # Get all attributes
    attributes = Verifier.get_entities(dsl_state, [:attributes])

    # Find attributes defined with feistel_cipher_target
    # These have the __feistel_cipher_target__ marker
    feistel_targets =
      attributes
      |> Enum.filter(fn attr ->
        Map.get(attr, :__feistel_cipher_target__, false)
      end)
      |> Enum.map(& &1.name)

    # Get encrypt configurations (entities are directly under [:feistel_cipher])
    encrypts = Verifier.get_entities(dsl_state, [:feistel_cipher])
    encrypt_targets = Enum.map(encrypts, & &1.target)

    # Find feistel_cipher_targets that don't have encrypt configs
    missing_encrypts = feistel_targets -- encrypt_targets

    if missing_encrypts != [] do
      {:error,
       Spark.Error.DslError.exception(
         module: Verifier.get_persisted(dsl_state, :module),
         message: """
         The following attributes are declared as `feistel_cipher_target` but have no corresponding `encrypt` configuration:
         #{Enum.map_join(missing_encrypts, ", ", &inspect/1)}

         Either add an `encrypt` block for each target:

             feistel_cipher do
               encrypt do
                 source :seq
                 target :#{List.first(missing_encrypts) || "attribute"}
               end
             end

         Or use `attribute` instead of `feistel_cipher_target` if encryption is not needed.
         """,
         path: [:feistel_cipher]
       )}
    else
      :ok
    end
  end
end
