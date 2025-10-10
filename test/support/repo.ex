defmodule AshFeistelCipher.Test.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :ash_feistel_cipher,
    adapter: Ecto.Adapters.Postgres
end
