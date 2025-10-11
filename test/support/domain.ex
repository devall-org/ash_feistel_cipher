defmodule AshFeistelCipher.Test.Domain do
  @moduledoc false
  use Ash.Domain, otp_app: :ash_feistel_cipher

  resources do
    resource AshFeistelCipher.Test.ValidResource
    resource AshFeistelCipher.Test.MultipleEncryptsResource
    resource AshFeistelCipher.Test.CustomBitsResource
    resource AshFeistelCipher.Test.CustomKeyResource
    resource AshFeistelCipher.Test.CustomSourceResource
    resource AshFeistelCipher.Test.CustomFunctionsPrefixResource
    resource AshFeistelCipher.Test.CustomSchemaResource
    resource AshFeistelCipher.Test.CustomRoundsResource
  end
end
