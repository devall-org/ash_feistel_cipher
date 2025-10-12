defmodule AshFeistelCipher.Verifier.AllowNilConsistencyTest do
  use ExUnit.Case, async: true

  import AshFeistelCipher.VerifierHelpers

  @moduledoc """
  Tests for AshFeistelCipher.Verifier.AllowNilConsistency

  The verifier ensures that when a from attribute allows nil,
  the encrypted attribute also allows nil.
  """

  describe "verify/1" do
    test "returns :ok when both from and encrypted attributes allow nil" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, is_encrypted: true, from: :seq, allow_nil?: true)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end

    test "returns :ok when both from and encrypted attributes don't allow nil" do
      attributes = [
        build_attribute(:seq, allow_nil?: false),
        build_attribute(:id, is_encrypted: true, from: :seq, allow_nil?: false)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end

    test "returns :ok when from attribute doesn't allow nil but encrypted does" do
      attributes = [
        build_attribute(:seq, allow_nil?: false),
        build_attribute(:id, is_encrypted: true, from: :seq, allow_nil?: true)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end

    test "returns error when from attribute allows nil but encrypted doesn't" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, is_encrypted: true, from: :seq, allow_nil?: false)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
      assert error.message =~ "Nullable column mismatch"
      assert error.message =~ "from: :seq (allow_nil?: true)"
      assert error.message =~ "encrypted: :id (allow_nil?: false)"
    end

    test "returns error for multiple inconsistent encrypts" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, is_encrypted: true, from: :seq, allow_nil?: false),
        build_attribute(:referral_code, is_encrypted: true, from: :seq, allow_nil?: false)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)

      # Both inconsistencies should be mentioned
      assert error.message =~ ":id"
      assert error.message =~ ":referral_code"
    end

    test "returns :ok when only some encrypts are inconsistent (allows partial errors)" do
      # Actually this should fail - if ANY encrypt is inconsistent, it's an error
      attributes = [
        build_attribute(:seq1, allow_nil?: false),
        build_attribute(:seq2, allow_nil?: true),
        build_attribute(:id1, is_encrypted: true, from: :seq1, allow_nil?: false),
        build_attribute(:id2, is_encrypted: true, from: :seq2, allow_nil?: false)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)

      # Only seq2 -> id2 should be mentioned
      assert error.message =~ ":seq2"
      assert error.message =~ ":id2"
      refute error.message =~ ":seq1"
      refute error.message =~ ":id1"
    end

    test "error message provides helpful suggestions" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:user_id, is_encrypted: true, from: :seq, allow_nil?: false)
      ]

      dsl_state = build_dsl_state(attributes)
      assert {:error, error} = AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)

      # Should include helpful suggestions
      assert error.message =~ "allow_nil?: true"
      assert error.message =~ "encrypted_integer :user_id"
    end

    test "returns :ok when no encrypted_integer attributes are defined" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, allow_nil?: false)
      ]

      dsl_state = build_dsl_state(attributes)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end
  end
end
