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
      assert statement.up != nil
      assert statement.down != nil

      # Verify up SQL contains expected elements
      assert statement.up =~ "CREATE TRIGGER"
      assert statement.up =~ "valid_resources_encrypt_seq_to_id_trigger"
      assert statement.up =~ "public.valid_resources"
      assert statement.up =~ "feistel_column_trigger"
      assert statement.up =~ "'seq'"
      assert statement.up =~ "'id'"
      # default bits
      assert statement.up =~ "52"

      # Verify down SQL
      assert statement.down =~ "DROP TRIGGER"
      assert statement.down =~ "valid_resources_encrypt_seq_to_id_trigger"
    end

    test "transforms multiple encrypt configurations" do
      statements = get_custom_statements(AshFeistelCipher.Test.MultipleEncryptsResource)

      assert length(statements) == 2

      # Check that both triggers are created
      up_sqls = Enum.map(statements, & &1.up)
      assert Enum.any?(up_sqls, &(&1 =~ "seq_to_id_trigger"))
      assert Enum.any?(up_sqls, &(&1 =~ "seq_to_referral_code_trigger"))

      # Verify first encrypt (seq -> id) with default bits 52
      id_statement = Enum.find(statements, &(&1.up =~ "seq_to_id_trigger"))
      assert id_statement.up =~ "'seq'"
      assert id_statement.up =~ "'id'"
      assert id_statement.up =~ "52"

      # Verify second encrypt (seq -> referral_code) with custom bits and key
      referral_statement = Enum.find(statements, &(&1.up =~ "seq_to_referral_code_trigger"))
      assert referral_statement.up =~ "'seq'"
      assert referral_statement.up =~ "'referral_code'"
      assert referral_statement.up =~ "40"
      assert referral_statement.up =~ "12345"
    end
  end

  describe "transform/1 - custom configurations" do
    test "applies custom bits configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomBitsResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "40"
      # should not use default
      refute statement.up =~ "52"
    end

    test "applies custom key configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomKeyResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "999888777"
    end

    test "applies custom rounds configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomRoundsResource)

      assert length(statements) == 1
      [statement] = statements

      # Should have rounds parameter (8)
      assert statement.up =~ ", 8)"
    end

    test "uses default rounds (16) when not specified" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      assert length(statements) == 1
      [statement] = statements

      # Should have default rounds (16)
      assert statement.up =~ ", 16)"
    end

    test "applies custom functions_prefix configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomFunctionsPrefixResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "crypto.feistel_column_trigger"
      refute statement.up =~ "public.feistel_column_trigger"
    end

    test "applies custom postgres schema configuration" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomSchemaResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.up =~ "accounts.custom_schema_resources"
      refute statement.up =~ "public.custom_schema_resources"
    end

    test "handles custom source attribute names (DB column mapping)" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomSourceResource)

      assert length(statements) == 1
      [statement] = statements

      # Should use DB column names (seq_num, enc_id) not attribute names
      assert statement.up =~ "'seq_num'"
      assert statement.up =~ "'enc_id'"
      refute statement.up =~ "'sequence_number'"
      refute statement.up =~ "'encrypted_id'"
    end
  end

  describe "validate_unique_target!/1" do
    test "raises error when same target is used multiple times" do
      assert_raise RuntimeError, ~r/id is used for multiple encrypts/, fn ->
        defmodule DuplicateTargetResource do
          use Ash.Resource,
            domain: AshFeistelCipher.Test.Domain,
            data_layer: AshPostgres.DataLayer,
            extensions: [AshFeistelCipher]

          postgres do
            table "duplicate_target"
            repo AshFeistelCipher.Test.Repo
          end

          attributes do
            integer_sequence :seq
            attribute :another_seq, :integer
            attribute :id, :integer
          end

          feistel_cipher do
            encrypt do
              source :seq
              target :id
            end

            encrypt do
              source :another_seq
              # Duplicate target - should raise error
              target :id
            end
          end
        end
      end
    end

    test "allows multiple encrypts with different targets" do
      # This should not raise an error
      statements = get_custom_statements(AshFeistelCipher.Test.MultipleEncryptsResource)

      assert length(statements) == 2
    end
  end

  describe "down SQL generation" do
    test "generates down SQL with safety guard" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      assert length(statements) == 1
      [statement] = statements

      assert statement.down =~ "RAISE EXCEPTION"
      assert statement.down =~ "DROP TRIGGER"
    end

    test "down SQL drops all triggers for multiple encrypts" do
      statements = get_custom_statements(AshFeistelCipher.Test.MultipleEncryptsResource)

      assert length(statements) == 2

      down_sqls = Enum.map(statements, & &1.down)
      assert Enum.all?(down_sqls, &(&1 =~ "DROP TRIGGER"))
      assert Enum.any?(down_sqls, &(&1 =~ "seq_to_id_trigger"))
      assert Enum.any?(down_sqls, &(&1 =~ "seq_to_referral_code_trigger"))
    end
  end

  describe "integration with FeistelCipher" do
    test "uses correct encryption key generation" do
      statements = get_custom_statements(AshFeistelCipher.Test.ValidResource)

      [statement] = statements

      # The key should be generated from table name, source, target, and bits
      # We can verify this by checking that the SQL contains a numeric key
      # Extract key from SQL: EXECUTE PROCEDURE ...feistel_column_trigger(bits, key, 'source', 'target')
      # The key is the second parameter
      key_pattern = ~r/feistel_column_trigger\((\d+),\s*(\d+),/
      assert [[_, _bits_str, key_str]] = Regex.scan(key_pattern, statement.up)
      key = String.to_integer(key_str)

      # Key should be a positive integer less than 2^31
      assert key > 0
      assert key < :math.pow(2, 31)
    end

    test "preserves custom key when provided" do
      statements = get_custom_statements(AshFeistelCipher.Test.CustomKeyResource)

      [statement] = statements

      # Should use the custom key 999888777
      assert statement.up =~ "999888777"
    end
  end

  describe "transformer ordering" do
    test "transformer runs before other transformers" do
      # The before?/1 callback should always return true
      assert AshFeistelCipher.Transformer.before?(:any_transformer) == true
      assert AshFeistelCipher.Transformer.before?(SomeOtherTransformer) == true
    end
  end
end
