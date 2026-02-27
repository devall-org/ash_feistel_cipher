defmodule AshFeistelCipher.Test.ValidResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "valid_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq
    encrypted_integer :id, from: :seq, primary_key?: true, allow_nil?: false, public?: true
    attribute :name, :string
  end
end

defmodule AshFeistelCipher.Test.MultipleEncryptsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "multiple_encrypts"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq

    encrypted_integer :id,
      from: :seq,
      data_bits: 52,
      primary_key?: true,
      allow_nil?: false,
      public?: true

    encrypted_integer :referral_code, from: :seq, data_bits: 38, key: 12345
    attribute :name, :string
  end
end

defmodule AshFeistelCipher.Test.CustomBitsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "custom_bits_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq

    encrypted_integer :id,
      from: :seq,
      data_bits: 40,
      primary_key?: true,
      allow_nil?: false,
      public?: true
  end
end

defmodule AshFeistelCipher.Test.CustomKeyResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "custom_key_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq

    encrypted_integer :id,
      from: :seq,
      key: 999_888_777,
      primary_key?: true,
      allow_nil?: false,
      public?: true
  end
end

defmodule AshFeistelCipher.Test.CustomSourceResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "custom_source_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    attribute :sequence_number, :integer, primary_key?: true, allow_nil?: false, source: :seq_num
    encrypted_integer :encrypted_id, from: :sequence_number, source: :enc_id
  end
end

defmodule AshFeistelCipher.Test.CustomFunctionsPrefixResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "custom_prefix_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq

    encrypted_integer :id,
      from: :seq,
      functions_prefix: "crypto",
      primary_key?: true,
      allow_nil?: false,
      public?: true
  end
end

defmodule AshFeistelCipher.Test.CustomSchemaResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "custom_schema_resources"
    schema "accounts"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq
    encrypted_integer :id, from: :seq, allow_nil?: false, primary_key?: true
  end
end

defmodule AshFeistelCipher.Test.CustomRoundsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "custom_rounds_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq

    encrypted_integer :id,
      from: :seq,
      rounds: 8,
      primary_key?: true,
      allow_nil?: false,
      public?: true
  end
end

defmodule AshFeistelCipher.Test.PrimaryKeyResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "primary_key_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq
    encrypted_integer_primary_key :id, from: :seq
    attribute :name, :string
  end
end

defmodule AshFeistelCipher.Test.TimeBitsZeroResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "time_bits_zero_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq

    encrypted_integer :id,
      from: :seq,
      time_bits: 0,
      primary_key?: true,
      allow_nil?: false,
      public?: true
  end
end

defmodule AshFeistelCipher.Test.PrimaryKeyCustomOptionsResource do
  @moduledoc false
  use Ash.Resource,
    domain: AshFeistelCipher.Test.Domain,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "primary_key_custom_resources"
    repo AshFeistelCipher.Test.Repo
  end

  attributes do
    integer_sequence :seq
    encrypted_integer_primary_key :id, from: :seq, data_bits: 38, key: 12345, rounds: 8
    attribute :name, :string
  end
end
