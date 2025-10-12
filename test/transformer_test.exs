defmodule AshFeistelCipher.TransformerTest do
  use ExUnit.Case, async: true

  # Helper to get custom statements from a resource
  defp get_custom_statements(resource) do
    resource
    |> AshPostgres.DataLayer.Info.custom_statements()
    |> Enum.filter(&(&1.name == :feistel_cipher))
  end

  describe "transform/1 - basic functionality" do
    test "transforms single encrypt configuration into custom_statement" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.name == :feistel_cipher
      assert statement.code? == true
      assert statement.up != nil
      assert statement.down != nil

      # Verify up contains function call with expected parameters
      assert statement.up =~ "FeistelCipher.up_for_trigger"
      assert statement.up =~ "\"public\""
      assert statement.up =~ "\"valid_resources\""
      assert statement.up =~ ":seq"
      assert statement.up =~ ":id"
      # default bits
      assert statement.up =~ "bits: 52"
      # default rounds
      assert statement.up =~ "rounds: 16"
      assert statement.up =~ "functions_prefix: \"public\""

      # Verify down contains function call
      assert statement.down =~ "FeistelCipher.down_for_trigger"
      assert statement.down =~ "\"public\""
      assert statement.down =~ "\"valid_resources\""
      assert statement.down =~ ":seq"
      assert statement.down =~ ":id"
    end

    test "transforms multiple encrypt configurations" do
      statements = get_custom_statements(AshFeistelCipher.Test.MultipleEncryptsResource)

      assert length(statements) == 2

      # Check that both function calls are created
      up_sqls = Enum.map(statements, & &1.up)
      assert Enum.all?(up_sqls, &(&1 =~ "FeistelCipher.up_for_trigger"))

      # Verify first encrypt (seq -> id) with default bits 52
      id_statement = Enum.find(statements, &(&1.up =~ ":id,"))
      assert id_statement.up =~ ":seq"
      assert id_statement.up =~ ":id"
      assert id_statement.up =~ "bits: 52"

      # Verify second encrypt (seq -> referral_code) with custom bits and key
      referral_statement = Enum.find(statements, &(&1.up =~ ":referral_code,"))
      assert referral_statement.up =~ ":seq"
      assert referral_statement.up =~ ":referral_code"
      assert referral_statement.up =~ "bits: 40"
      assert referral_statement.up =~ "key: 12345"
    end
  end

  describe "transform/1 - custom configurations" do
    test "applies custom bits configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomBitsResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "bits: 40"
      # should not use default
      refute statement.up =~ "bits: 52"
    end

    test "applies custom key configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomKeyResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "key: 999888777"
    end

    test "applies custom rounds configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomRoundsResource)

      assert length(statements) == 1
      [statement] = statements

      # Should have rounds parameter (8)
      assert statement.up =~ "rounds: 8"
    end

    test "uses default rounds (16) when not specified" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      assert length(statements) == 1
      [statement] = statements

      # Should have default rounds (16)
      assert statement.up =~ "rounds: 16"
    end

    test "applies custom functions_prefix configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomFunctionsPrefixResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "functions_prefix: \"crypto\""
      refute statement.up =~ "functions_prefix: \"public\""
    end

    test "applies custom postgres schema configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomSchemaResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "\"accounts\""
      assert statement.up =~ "\"custom_schema_resources\""
      refute statement.up =~ "\"public\", \"custom_schema_resources\""
    end

    test "handles custom source attribute names (DB column mapping)" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomSourceResource)

      assert length(statements) == 1
      [statement] = statements

      # Should use DB column names (seq_num, enc_id) not attribute names
      assert statement.up =~ ":seq_num"
      assert statement.up =~ ":enc_id"
      refute statement.up =~ ":sequence_number"
      refute statement.up =~ ":encrypted_id"
    end
  end

  describe "down SQL generation" do
    test "generates down SQL with function call" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.down =~ "FeistelCipher.down_for_trigger"
      assert statement.down =~ "\"public\""
      assert statement.down =~ "\"valid_resources\""
      assert statement.down =~ ":seq"
      assert statement.down =~ ":id"
    end

    test "down SQL for all triggers for multiple encrypts" do
      statements = get_custom_statements(AshFeistelCipher.Test.MultipleEncryptsResource)

      assert length(statements) == 2

      down_sqls = Enum.map(statements, & &1.down)
      assert Enum.all?(down_sqls, &(&1 =~ "FeistelCipher.down_for_trigger"))
      assert Enum.any?(down_sqls, &(&1 =~ ":id"))
      assert Enum.any?(down_sqls, &(&1 =~ ":referral_code"))
    end
  end

  describe "integration with FeistelCipher" do
    test "uses correct encryption key generation" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      [statement] = statements

      # The key should be nil when not provided (auto-generated)
      # The function call should have key: nil
      assert statement.up =~ "key: nil"
    end

    test "preserves custom key when provided" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomKeyResource)

      [statement] = statements

      # Should use the custom key 999888777
      assert statement.up =~ "key: 999888777"
    end
  end

  describe "transformer ordering" do
    test "transformer runs before other transformers" do
      # The before?/1 callback should always return true
      assert AshFeistelCipher.Transformer.before?(:any_transformer) == true
      assert AshFeistelCipher.Transformer.before?(SomeOtherTransformer) == true
    end
  end

  describe "encrypted_integer_primary_key" do
    test "sets primary_key, allow_nil, and public defaults" do
      statements = get_custom_statements(AshFeistelCipher.Test.PrimaryKeyResource)

      assert length(statements) == 1
      [statement] = statements

      # Verify function call is created correctly
      assert statement.up =~ "FeistelCipher.up_for_trigger"
      assert statement.up =~ "\"public\""
      assert statement.up =~ "\"primary_key_resources\""

      # Verify the attribute has correct defaults via Ash.Resource.Info
      resource = AshFeistelCipher.Test.PrimaryKeyResource
      id_attr = Ash.Resource.Info.attribute(resource, :id)

      assert id_attr.primary_key? == true
      assert id_attr.allow_nil? == false
      assert id_attr.public? == true
      assert id_attr.writable? == false
      assert id_attr.generated? == true
    end

    test "allows overriding encryption options (bits, key, rounds)" do
      statements = get_custom_statements(AshFeistelCipher.Test.PrimaryKeyCustomOptionsResource)

      assert length(statements) == 1
      [statement] = statements

      # Verify custom bits (40)
      assert statement.up =~ "bits: 40"
      refute statement.up =~ "bits: 52"

      # Verify custom key (12345)
      assert statement.up =~ "key: 12345"

      # Verify custom rounds (8)
      assert statement.up =~ "rounds: 8"
      refute statement.up =~ "rounds: 16"

      # Verify the attribute still has primary_key defaults
      resource = AshFeistelCipher.Test.PrimaryKeyCustomOptionsResource
      id_attr = Ash.Resource.Info.attribute(resource, :id)

      assert id_attr.primary_key? == true
      assert id_attr.allow_nil? == false
      assert id_attr.public? == true
    end

    test "generates correct trigger SQL" do
      statements = get_custom_statements(AshFeistelCipher.Test.PrimaryKeyResource)

      [statement] = statements

      # Verify function call structure
      assert statement.up =~ "FeistelCipher.up_for_trigger"
      assert statement.up =~ ":seq"
      assert statement.up =~ ":id"

      # Verify down function call
      assert statement.down =~ "FeistelCipher.down_for_trigger"
      assert statement.down =~ "\"public\""
      assert statement.down =~ "\"primary_key_resources\""
      assert statement.down =~ ":seq"
      assert statement.down =~ ":id"
    end
  end
end
