defmodule AshFeistelCipher.Test.ValidResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("valid_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
    attribute(:name, :string)
  end

  feistel_cipher do
    encrypt do
      source(:seq)
      target(:id)
    end
  end
end

defmodule AshFeistelCipher.Test.MultipleEncryptsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("multiple_encrypts")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
    attribute(:referral_code, :integer)
    attribute(:name, :string)
  end

  feistel_cipher do
    encrypt do
      source(:seq)
      target(:id)
      bits(52)
    end

    encrypt do
      source(:seq)
      target(:referral_code)
      bits(40)
      key(12345)
    end
  end
end

defmodule AshFeistelCipher.Test.CustomBitsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_bits_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
  end

  feistel_cipher do
    encrypt do
      source(:seq)
      target(:id)
      bits(40)
    end
  end
end

defmodule AshFeistelCipher.Test.CustomKeyResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_key_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
  end

  feistel_cipher do
    encrypt do
      source(:seq)
      target(:id)
      key(999_888_777)
    end
  end
end

defmodule AshFeistelCipher.Test.CustomSourceResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_source_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    attribute(:sequence_number, :integer, primary_key?: true, allow_nil?: false, source: :seq_num)
    attribute(:encrypted_id, :integer, source: :enc_id)
  end

  feistel_cipher do
    encrypt do
      source(:sequence_number)
      target(:encrypted_id)
    end
  end
end

defmodule AshFeistelCipher.Test.CustomFunctionsPrefixResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_prefix_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
  end

  feistel_cipher do
    functions_prefix("crypto")

    encrypt do
      source(:seq)
      target(:id)
    end
  end
end

defmodule AshFeistelCipher.Test.CustomSchemaResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_schema_resources")
    schema("accounts")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
  end

  feistel_cipher do
    encrypt do
      source(:seq)
      target(:id)
    end
  end
end

defmodule AshFeistelCipher.Test.CustomRoundsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table("custom_rounds_resources")
    repo(AshFeistelCipher.Test.Repo)
  end

  attributes do
    integer_primary_key(:seq)
    attribute(:id, :integer)
  end

  feistel_cipher do
    encrypt do
      source(:seq)
      target(:id)
      rounds(8)
    end
  end
end
