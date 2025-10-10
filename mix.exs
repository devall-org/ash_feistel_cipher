defmodule AshFeistelCipher.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_feistel_cipher,
      version: "0.9.0",
      elixir: "~> 1.17",
      consolidate_protocols: Mix.env() not in [:dev, :test],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description:
        "Ash extension that transforms integer attributes using a Feistel cipher via Postgres triggers.",
      package: package(),
      source_url: "https://github.com/devall-org/ash_feistel_cipher",
      homepage_url: "https://github.com/devall-org/ash_feistel_cipher",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:igniter, "~> 0.6", optional: true},
      {:feistel_cipher, "~> 0.9.0"},
      {:ash, "~> 3.0"},
      {:ash_postgres, "~> 2.0"},
      {:spark, "~> 2.0"},
      {:sourceror, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "ash_feistel_cipher",
      licenses: ["MIT"],
      maintainers: ["Jechol Lee"],
      links: %{
        "GitHub" => "https://github.com/devall-org/ash_feistel_cipher"
      },
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end
