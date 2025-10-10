defmodule AshFeistelCipher.Test.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource(AshFeistelCipher.Test.ValidResource)
    resource(AshFeistelCipher.Test.MultipleEncryptsResource)
    resource(AshFeistelCipher.Test.CustomBitsResource)
    resource(AshFeistelCipher.Test.CustomKeyResource)
    resource(AshFeistelCipher.Test.CustomSourceResource)
    resource(AshFeistelCipher.Test.CustomFunctionsPrefixResource)
    resource(AshFeistelCipher.Test.CustomSchemaResource)
  end
end
