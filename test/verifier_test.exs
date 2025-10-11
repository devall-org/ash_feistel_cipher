defmodule AshFeistelCipher.VerifierTest do
  use ExUnit.Case, async: true

  alias Spark.Dsl.Transformer

  @moduledoc """
  Tests for AshFeistelCipher.Verifier

  The verifier ensures that all `feistel_cipher_target` attributes have
  corresponding `encrypt` configurations.
  """

  # Helper to build a mock dsl_state for testing
  defp build_dsl_state(attributes, encrypts) do
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

  defp build_attribute(name, is_target) do
    base_attr = %{
      name: name,
      type: :integer,
      source: name
    }

    if is_target do
      Map.put(base_attr, :__feistel_cipher_target__, true)
    else
      base_attr
    end
  end

  defp build_encrypt(source, target) do
    %AshFeistelCipher.Encrypt{
      source: source,
      target: target,
      bits: 52,
      key: nil,
      rounds: 16
    }
  end

  describe "verify/1 - direct verifier testing" do
    test "returns :ok when all feistel_cipher_target attributes have corresponding encrypts" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:id, true)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.verify(dsl_state)
    end

    test "returns :ok when no feistel_cipher_target attributes exist" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:id, false)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.verify(dsl_state)
    end

    test "returns error when feistel_cipher_target has no corresponding encrypt" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:id, true)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.verify(dsl_state)
      assert error.message =~ "no corresponding `encrypt` configuration"
      assert error.message =~ ":id"
    end

    test "returns error with all missing attributes listed" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:id, true),
        build_attribute(:referral_code, true)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.verify(dsl_state)

      # Both missing attributes should be mentioned
      assert error.message =~ ":id"
      assert error.message =~ ":referral_code"
    end

    test "returns error when only some targets have encrypt blocks" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:id, true),
        build_attribute(:referral_code, true)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.verify(dsl_state)

      # Only referral_code should be mentioned (id has encrypt)
      assert error.message =~ ":referral_code"
      refute error.message =~ ":id,"
    end

    test "error message provides helpful suggestions" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:user_id, true)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.verify(dsl_state)

      # Should include helpful suggestions
      assert error.message =~ "encrypt do"
      assert error.message =~ "source :seq"
      assert error.message =~ "target :user_id"
      assert error.message =~ "use `attribute` instead"
    end

    test "returns :ok for multiple valid encrypts" do
      attributes = [
        build_attribute(:seq, false),
        build_attribute(:id, true),
        build_attribute(:referral_code, true)
      ]

      encrypts = [
        build_encrypt(:seq, :id),
        build_encrypt(:seq, :referral_code)
      ]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.verify(dsl_state)
    end
  end
end
