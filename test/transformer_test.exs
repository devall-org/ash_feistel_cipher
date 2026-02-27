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
      assert statement.up =~ "FeistelCipher.up_for_v1_trigger"
      assert statement.up =~ "\"public\""
      assert statement.up =~ "\"valid_resources\""
      assert statement.up =~ ":seq"
      assert statement.up =~ ":id"
      # default time_bits
      assert statement.up =~ "time_bits: 15"
      # default data_bits
      assert statement.up =~ "data_bits: 38"
      assert statement.up =~ "time_offset: 0"
      # default rounds
      assert statement.up =~ "rounds: 16"
      assert statement.up =~ "functions_prefix: \"public\""

      # Verify down contains function call
      assert statement.down =~ "FeistelCipher.down_for_v1_trigger"
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
      assert Enum.all?(up_sqls, &(&1 =~ "FeistelCipher.up_for_v1_trigger"))

      # Verify first encrypt (seq -> id) with custom data_bits 52
      id_statement = Enum.find(statements, &(&1.up =~ ":id,"))
      assert id_statement.up =~ ":seq"
      assert id_statement.up =~ ":id"
      assert id_statement.up =~ "data_bits: 52"

      # Verify second encrypt (seq -> referral_code) with custom data_bits and key
      referral_statement = Enum.find(statements, &(&1.up =~ ":referral_code,"))
      assert referral_statement.up =~ ":seq"
      assert referral_statement.up =~ ":referral_code"
      assert referral_statement.up =~ "data_bits: 38"
      assert referral_statement.up =~ "key: 12_345"
    end
  end

  describe "transform/1 - custom configurations" do
    test "applies custom bits configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomBitsResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "data_bits: 40"
    end

    test "applies custom key configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomKeyResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "key: 999_888_777"
    end

    test "applies custom rounds configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomRoundsResource)

      assert length(statements) == 1
      [statement] = statements

      # Should have rounds parameter (8)
      assert statement.up =~ "rounds: 8"
    end

    test "applies custom time_offset configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomTimeOffsetResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "time_offset: 21600"
      refute statement.up =~ "time_offset: 0"
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

    test "passes default time options when time_bits is 0" do
      statements = get_custom_statements(AshFeistelCipher.Test.TimeBitsZeroResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "time_bits: 0"
      assert statement.up =~ "time_bucket: 86400"
      assert statement.up =~ "time_offset: 0"
      assert statement.up =~ "encrypt_time: false"
    end
  end

  describe "down SQL generation" do
    test "generates down SQL with function call" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.down =~ "FeistelCipher.down_for_v1_trigger"
      assert statement.down =~ "\"public\""
      assert statement.down =~ "\"valid_resources\""
      assert statement.down =~ ":seq"
      assert statement.down =~ ":id"
    end

    test "down SQL for all triggers for multiple encrypts" do
      statements = get_custom_statements(AshFeistelCipher.Test.MultipleEncryptsResource)

      assert length(statements) == 2

      down_sqls = Enum.map(statements, & &1.down)
      assert Enum.all?(down_sqls, &(&1 =~ "FeistelCipher.down_for_v1_trigger"))
      assert Enum.any?(down_sqls, &(&1 =~ ":id"))
      assert Enum.any?(down_sqls, &(&1 =~ ":referral_code"))
    end
  end

  describe "integration with FeistelCipher" do
    test "uses correct encryption key generation" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      [statement] = statements

      # The key should be generated at compile time and be a numeric value
      # Extract key from the statement
      assert [_, key_str] = Regex.run(~r/key: (\d+)/, statement.up)
      key = String.to_integer(key_str)

      # Key should be a positive integer less than 2^31
      assert key > 0
      assert key < :math.pow(2, 31)
    end

    test "preserves custom key when provided" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomKeyResource)

      [statement] = statements

      # Should use the custom key with underscores
      assert statement.up =~ "key: 999_888_777"
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
      assert statement.up =~ "FeistelCipher.up_for_v1_trigger"
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

    test "allows overriding encryption options (data_bits, key, rounds)" do
      statements = get_custom_statements(AshFeistelCipher.Test.PrimaryKeyCustomOptionsResource)

      assert length(statements) == 1
      [statement] = statements

      # Verify custom data_bits (38)
      assert statement.up =~ "data_bits: 38"

      # Verify custom key with underscores
      assert statement.up =~ "key: 12_345"

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
      assert statement.up =~ "FeistelCipher.up_for_v1_trigger"
      assert statement.up =~ ":seq"
      assert statement.up =~ ":id"

      # Verify down function call
      assert statement.down =~ "FeistelCipher.down_for_v1_trigger"
      assert statement.down =~ "\"public\""
      assert statement.down =~ "\"primary_key_resources\""
      assert statement.down =~ ":seq"
      assert statement.down =~ ":id"
    end
  end
end
