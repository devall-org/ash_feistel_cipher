defmodule AshFeistelCipher.Verifier.MissingEncryptTest do
  use ExUnit.Case, async: true

  import AshFeistelCipher.VerifierHelpers

  @moduledoc """
  Tests for AshFeistelCipher.Verifier.MissingEncrypt

  The verifier ensures that all `feistel_cipher_target` attributes have
  corresponding `encrypt` configurations.
  """

  describe "verify/1" do
    test "returns :ok when all feistel_cipher_target attributes have corresponding encrypts" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_target: true)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)
    end

    test "returns :ok when no feistel_cipher_target attributes exist" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)
    end

    test "returns error when feistel_cipher_target has no corresponding encrypt" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_target: true)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)
      assert error.message =~ "no corresponding `encrypt` configuration"
      assert error.message =~ ":id"
    end

    test "returns error with all missing attributes listed" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_target: true),
        build_attribute(:referral_code, is_target: true)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)

      # Both missing attributes should be mentioned
      assert error.message =~ ":id"
      assert error.message =~ ":referral_code"
    end

    test "returns error when only some targets have encrypt blocks" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_target: true),
        build_attribute(:referral_code, is_target: true)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)

      # Only referral_code should be mentioned (id has encrypt)
      assert error.message =~ ":referral_code"
      refute error.message =~ ":id,"
    end

    test "error message provides helpful suggestions" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:user_id, is_target: true)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)

      # Should include helpful suggestions
      assert error.message =~ "encrypt do"
      assert error.message =~ "source :seq"
      assert error.message =~ "target :user_id"
      assert error.message =~ "use `attribute` instead"
    end

    test "returns :ok for multiple valid encrypts" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_target: true),
        build_attribute(:referral_code, is_target: true)
      ]

      encrypts = [
        build_encrypt(:seq, :id),
        build_encrypt(:seq, :referral_code)
      ]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.MissingEncrypt.verify(dsl_state)
    end
  end
end
