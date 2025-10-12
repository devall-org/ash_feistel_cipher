defmodule AshFeistelCipher.Verifier.MissingSourceTest do
  use ExUnit.Case, async: true

  import AshFeistelCipher.VerifierHelpers

  @moduledoc """
  Tests for AshFeistelCipher.Verifier.MissingSource

  The verifier ensures that all `encrypted_integer` attributes have
  a `from` option configured.
  """

  describe "verify/1" do
    test "returns :ok when all encrypted_integer attributes have from configured" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_encrypted: true, from: :seq)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)
    end

    test "returns :ok when no encrypted_integer attributes exist" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)
    end

    test "returns error when encrypted_integer has no from configured" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_encrypted: true, from: nil)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)
      assert error.message =~ "no `from` configured"
      assert error.message =~ ":id"
    end

    test "returns error with all missing from attributes listed" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_encrypted: true, from: nil),
        build_attribute(:referral_code, is_encrypted: true, from: nil)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)

      # Both missing attributes should be mentioned
      assert error.message =~ ":id"
      assert error.message =~ ":referral_code"
    end

    test "returns error when only some encrypted attributes have from configured" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_encrypted: true, from: :seq),
        build_attribute(:referral_code, is_encrypted: true, from: nil)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)

      # Only referral_code should be mentioned (id has from)
      assert error.message =~ ":referral_code"
      refute error.message =~ ":id,"
    end

    test "error message provides helpful suggestions" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:user_id, is_encrypted: true, from: nil)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)

      # Should include helpful suggestions
      assert error.message =~ "encrypted_integer :user_id"
      assert error.message =~ "from: :seq"
      assert error.message =~ "use `attribute` instead"
    end

    test "returns :ok for multiple valid encrypted_integer attributes" do
      attributes = [
        build_attribute(:seq),
        build_attribute(:id, is_encrypted: true, from: :seq),
        build_attribute(:referral_code, is_encrypted: true, from: :seq)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.MissingSource.verify(dsl_state)
    end
  end
end
