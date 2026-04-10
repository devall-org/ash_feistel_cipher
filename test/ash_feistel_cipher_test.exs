defmodule AshFeistelCipherTest do
  use ExUnit.Case, async: true

  alias AshFeistelCipher.EncryptedIntegerAttribute

  describe "transform/1" do
    test "rejects user-provided default values" do
      entity =
        struct!(EncryptedIntegerAttribute,
          name: :id,
          type: :integer,
          from: :seq,
          default: 123,
          generated?: true,
          writable?: false
        )

      assert {:error, error} = AshFeistelCipher.transform(entity)
      assert error.message =~ "`default:` is not supported"
      assert error.message =~ "Remove `default:` from `id`"
    end

    test "uses internal sentinel when backfill is enabled" do
      entity =
        struct!(EncryptedIntegerAttribute,
          name: :id,
          type: :integer,
          from: :seq,
          backfill?: true,
          generated?: true,
          writable?: false
        )

      assert {:ok, attribute} = AshFeistelCipher.transform(entity)
      assert attribute.default == -1
    end

    test "uses internal sentinel when backfill is disabled" do
      entity =
        struct!(EncryptedIntegerAttribute,
          name: :id,
          type: :integer,
          from: :seq,
          backfill?: false,
          generated?: true,
          writable?: false
        )

      assert {:ok, attribute} = AshFeistelCipher.transform(entity)
      assert attribute.default == -1
    end
  end
end
