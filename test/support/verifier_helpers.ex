defmodule AshFeistelCipher.VerifierHelpers do
  @moduledoc """
  Common helper functions for verifier tests.
  """

  alias Spark.Dsl.Transformer

  @doc """
  Builds a mock dsl_state for testing verifiers.
  """
  def build_dsl_state(attributes, encrypts) do
    dsl_state = %{}

    dsl_state =
      Enum.reduce(attributes, dsl_state, fn attr, state ->
        Transformer.add_entity(state, [:attributes], attr)
      end)

    dsl_state =
      Enum.reduce(encrypts, dsl_state, fn encrypt, state ->
        Transformer.add_entity(state, [:feistel_cipher], encrypt)
      end)

    Transformer.persist(dsl_state, :module, TestModule)
  end

  @doc """
  Builds a mock attribute for testing.

  ## Options
  - `:is_target` - Whether this is a feistel_cipher_target (default: false)
  - `:allow_nil?` - Whether the attribute allows nil (default: false)
  """
  def build_attribute(name, opts \\ []) do
    is_target = Keyword.get(opts, :is_target, false)
    allow_nil? = Keyword.get(opts, :allow_nil?, false)

    base_attr = %{
      name: name,
      type: :integer,
      source: name,
      allow_nil?: allow_nil?
    }

    if is_target do
      Map.put(base_attr, :__feistel_cipher_target__, true)
    else
      base_attr
    end
  end

  @doc """
  Builds a mock encrypt configuration for testing.
  """
  def build_encrypt(source, target) do
    %AshFeistelCipher.Encrypt{
      source: source,
      target: target,
      bits: 52,
      key: nil,
      rounds: 16
    }
  end
end
