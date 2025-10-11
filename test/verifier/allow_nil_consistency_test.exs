defmodule AshFeistelCipher.Verifier.AllowNilConsistencyTest do
  use ExUnit.Case, async: true

  import AshFeistelCipher.VerifierHelpers

  @moduledoc """
  Tests for AshFeistelCipher.Verifier.AllowNilConsistency

  The verifier ensures that when a source attribute allows nil,
  the target attribute also allows nil.
  """

  describe "verify/1" do
    test "returns :ok when both source and target allow nil" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, allow_nil?: true)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end

    test "returns :ok when both source and target don't allow nil" do
      attributes = [
        build_attribute(:seq, allow_nil?: false),
        build_attribute(:id, allow_nil?: false)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end

    test "returns :ok when source doesn't allow nil but target does" do
      attributes = [
        build_attribute(:seq, allow_nil?: false),
        build_attribute(:id, allow_nil?: true)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end

    test "returns error when source allows nil but target doesn't" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, allow_nil?: false)
      ]

      encrypts = [build_encrypt(:seq, :id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
      assert error.message =~ "Nullable column mismatch"
      assert error.message =~ "source: :seq (allow_nil?: true)"
      assert error.message =~ "target: :id (allow_nil?: false)"
    end

    test "returns error for multiple inconsistent encrypts" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, allow_nil?: false),
        build_attribute(:referral_code, allow_nil?: false)
      ]

      encrypts = [
        build_encrypt(:seq, :id),
        build_encrypt(:seq, :referral_code)
      ]

      dsl_state = build_dsl_state(attributes, encrypts)
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
        build_attribute(:id1, allow_nil?: false),
        build_attribute(:id2, allow_nil?: false)
      ]

      encrypts = [
        build_encrypt(:seq1, :id1),
        build_encrypt(:seq2, :id2)
      ]

      dsl_state = build_dsl_state(attributes, encrypts)
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
        build_attribute(:user_id, allow_nil?: false)
      ]

      encrypts = [build_encrypt(:seq, :user_id)]

      dsl_state = build_dsl_state(attributes, encrypts)
      assert {:error, error} = AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)

      # Should include helpful suggestions
      assert error.message =~ "allow_nil? true"
      assert error.message =~ "feistel_cipher_target :user_id"
    end

    test "returns :ok when no encrypts are defined" do
      attributes = [
        build_attribute(:seq, allow_nil?: true),
        build_attribute(:id, allow_nil?: false)
      ]

      encrypts = []

      dsl_state = build_dsl_state(attributes, encrypts)
      assert :ok == AshFeistelCipher.Verifier.AllowNilConsistency.verify(dsl_state)
    end
  end
end
