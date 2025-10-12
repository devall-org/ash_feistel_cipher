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
  - `:is_encrypted` - Whether this is an encrypted_integer attribute (default: false)
  - `:allow_nil?` - Whether the attribute allows nil (default: false)
  - `:from` - Source attribute for encrypted_integer (required if is_encrypted is true)
  """
  def build_attribute(name, opts \\ []) do
    is_encrypted = Keyword.get(opts, :is_encrypted, false)
    allow_nil? = Keyword.get(opts, :allow_nil?, false)
    from = Keyword.get(opts, :from)

    base_attr = %{
      name: name,
      type: :integer,
      source: name,
      allow_nil?: allow_nil?
    }

    if is_encrypted do
      base_attr
      |> Map.put(:__feistel_encrypted__, true)
      |> Map.put(:__feistel_from__, from)
    else
      base_attr
    end
  end
end
