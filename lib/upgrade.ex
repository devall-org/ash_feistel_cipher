defmodule Mix.Tasks.AshFeistelCipher.Upgrade.Docs do
  @moduledoc false

  def short_doc do
    "Generate a migration to upgrade FeistelCipher from v0.x to v1.0"
  end

  def example do
    "mix ash_feistel_cipher.upgrade"
  end

  def long_doc do
    """
    #{short_doc()}

    Generates an Ecto migration that upgrades the PostgreSQL functions from v0.x to v1.0.
    This composes `feistel_cipher.upgrade` with the same options.

    **Note**: Before running this task, you must manually update your Ash resource DSL
    to replace `bits:` with `time_bits: 0, data_bits:`. See UPGRADE.md for details.

    ## Example

    ```bash
    #{example()}
    ```

    ## Options

    * `--repo` or `-r` — Specify an Ecto repo for FeistelCipher to use.
    * `--functions-prefix` or `-p` — Specify the PostgreSQL schema prefix (default: `public`)
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshFeistelCipher.Upgrade do
    @shortdoc __MODULE__.Docs.short_doc()
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :ash,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        only: nil,
        positional: [],
        composes: ["feistel_cipher.upgrade"],
        schema: [repo: :string, functions_prefix: :string],
        defaults: [functions_prefix: "public"],
        aliases: [r: :repo, p: :functions_prefix],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options

      feistel_cipher_argv =
        []
        |> maybe_add_option("--repo", opts[:repo])
        |> maybe_add_option("--functions-prefix", opts[:functions_prefix])

      notice = """

      ⚠️  Next steps:
        1. Edit the generated migration to fill in your functions_salt
           (find it in the migration with timestamp 19730501000000)
        2. Run `mix ash.codegen --name upgrade_feistel_v1`
        3. In the generated migration, replace `down_for_trigger` with `force_down_for_trigger`
        4. Optionally add old function cleanup to the last migration

        See https://github.com/devall-org/ash_feistel_cipher/blob/main/UPGRADE.md
      """

      igniter
      |> Igniter.compose_task("feistel_cipher.upgrade", feistel_cipher_argv)
      |> Igniter.add_notice(notice)
    end

    defp maybe_add_option(argv, _flag, nil), do: argv
    defp maybe_add_option(argv, flag, value), do: argv ++ [flag, to_string(value)]
  end
else
  defmodule Mix.Tasks.AshFeistelCipher.Upgrade do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'ash_feistel_cipher.upgrade' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
