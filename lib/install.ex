defmodule Mix.Tasks.AshFeistelCipher.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs AshFeistelCipher and FeistelCipher"
  end

  def example do
    "mix igniter.install ash_feistel_cipher"
  end

  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```

    ## Options

    * `--repo` or `-r` — Specify an Ecto repo for FeistelCipher to use.
    * `--functions-prefix` or `-p` — Specify the PostgreSQL schema prefix where the FeistelCipher functions will be created, defaults to `public`
    * `--functions-salt` or `-s` — Specify the constant value used in the Feistel cipher algorithm. Changing this value will result in different cipher outputs for the same input, should be less than 2^31, defaults to `#{FeistelCipher.default_functions_salt()}`
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshFeistelCipher.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()
    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        # Groups allow for overlapping arguments for tasks by the same author
        # See the generators guide for more.
        group: :ash,
        # dependencies to add
        adds_deps: [],
        # dependencies to add and call their associated installers, if they exist
        installs: [{:feistel_cipher, "~> 0.9.3"}],
        # An example invocation
        example: __MODULE__.Docs.example(),
        # A list of environments that this should be installed in.
        only: nil,
        # a list of positional arguments, i.e `[:file]`
        positional: [],
        # Other tasks your task composes using `Igniter.compose_task`, passing in the CLI argv
        # This ensures your option schema includes options from nested tasks
        composes: ["feistel_cipher.install"],
        # `OptionParser` schema
        schema: [repo: :string, functions_prefix: :string, functions_salt: :integer],
        # Default values for the options in the `schema`
        defaults: [
          functions_prefix: "public",
          functions_salt: FeistelCipher.default_functions_salt()
        ],
        # CLI aliases
        aliases: [r: :repo, p: :functions_prefix, s: :functions_salt],
        # A list of options in the schema that are required
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options

      # Compose feistel_cipher.install with the same options
      feistel_cipher_argv =
        []
        |> maybe_add_option("--repo", opts[:repo])
        |> maybe_add_option("--functions-prefix", opts[:functions_prefix])
        |> maybe_add_option("--functions-salt", opts[:functions_salt])

      igniter
      |> Igniter.compose_task("feistel_cipher.install", feistel_cipher_argv)
      |> Igniter.Project.Formatter.import_dep(:ash_feistel_cipher)
    end

    defp maybe_add_option(argv, _flag, nil), do: argv
    defp maybe_add_option(argv, flag, value), do: argv ++ [flag, to_string(value)]
  end
else
  defmodule Mix.Tasks.AshFeistelCipher.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'ash_feistel_cipher.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
