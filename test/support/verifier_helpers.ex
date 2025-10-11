defmodule AshFeistelCipher.VerifierHelpers do
  @moduledoc """
  Common helper functions for verifier tests.
  """

  alias Spark.Dsl.Transformer

  @doc """
  Builds a mock dsl_state for testing verifiers.
  Accepts only attributes (no separate encrypts needed).
  """
  def build_dsl_state(attributes) do
    dsl_state = %{}

    dsl_state =
      Enum.reduce(attributes, dsl_state, fn attr, state ->
        Transformer.add_entity(state, [:attributes], attr)
      end)

    Transformer.persist(dsl_state, :module, TestModule)
  end

  @doc """
  Builds a mock attribute for testing.

  ## Options
  - `:is_target` - Whether this is a feistel_encrypted (default: false)
  - `:allow_nil?` - Whether the attribute allows nil (default: false)
  - `:from` - Source attribute for feistel_encrypted (required if is_target is true)
  """
  def build_attribute(name, opts \\ []) do
    is_target = Keyword.get(opts, :is_target, false)
    allow_nil? = Keyword.get(opts, :allow_nil?, false)
    from = Keyword.get(opts, :from)

    base_attr = %{
      name: name,
      type: :integer,
      source: name,
      allow_nil?: allow_nil?
    }

    if is_target do
      base_attr
      |> Map.put(:__feistel_cipher_target__, true)
      |> Map.put(:__feistel_from__, from)
    else
      base_attr
    end
  end
end
