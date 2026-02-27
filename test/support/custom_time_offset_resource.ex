defmodule AshFeistelCipher.Test.CustomTimeOffsetResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_time_offset_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_sequence(:seq)

    encrypted_integer(:id,
      from: :seq,
      time_offset: 21_600,
      primary_key?: true,
      allow_nil?: false,
      public?: true
    )
  end
end
