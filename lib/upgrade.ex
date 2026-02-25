defmodule Mix.Tasks.AshFeistelCipher.Upgrade.Docs do
  @moduledoc false

  def short_doc do
    "Upgrade AshFeistelCipher DSL from v0.x to v1.0"
  end

  def example do
    "mix ash_feistel_cipher.upgrade"
  end

  def long_doc do
    """
    #{short_doc()}

    Updates Ash resource source files to use the v1.0 DSL:
    - Renames `bits: N` to `time_bits: 0, data_bits: N`
    - If no `bits` was specified, adds `time_bits: 0, data_bits: 52` (making old defaults explicit)

    Setting `time_bits: 0` ensures backward compatibility with existing encrypted data.

    ## Example

    ```bash
    #{example()}
    ```

    After running this task, also run `mix feistel_cipher.upgrade` to generate
    the database migration for upgrading the PostgreSQL functions.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.AshFeistelCipher.Upgrade do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

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
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> upgrade_dsl_calls(:encrypted_integer)
      |> upgrade_dsl_calls(:encrypted_integer_primary_key)
    end

    defp upgrade_dsl_calls(igniter, entity_name) do
      # Find all Elixir source files and transform bits: -> time_bits: 0 + data_bits:
      igniter
      |> Igniter.Project.Module.find_all_matching_modules(fn _module, zipper ->
        source = Sourceror.Zipper.root(zipper) |> Sourceror.to_string()
        String.contains?(source, to_string(entity_name))
      end)
      |> case do
        {igniter, []} ->
          igniter

        {igniter, modules} ->
          Enum.reduce(modules, igniter, fn {module_name, _}, igniter ->
            Igniter.Project.Module.find_and_update_module!(igniter, module_name, fn zipper ->
              transform_bits_to_data_bits(zipper, entity_name)
            end)
          end)
      end
    end

    defp transform_bits_to_data_bits(zipper, entity_name) do
      # Walk the AST to find entity_name calls with bits: option
      case find_entity_with_bits(zipper, entity_name) do
        nil ->
          {:ok, zipper}

        zipper ->
          zipper = replace_bits_with_data_bits(zipper)
          # Continue searching for more occurrences
          transform_bits_to_data_bits(zipper, entity_name)
      end
    end

    defp find_entity_with_bits(zipper, entity_name) do
      Igniter.Code.Common.move_to(zipper, fn node ->
        case node do
          {^entity_name, _, args} when is_list(args) ->
            args_str = Sourceror.to_string(node)
            String.contains?(args_str, "bits:")

          _ ->
            false
        end
      end)
      |> case do
        {:ok, zipper} -> zipper
        _ -> nil
      end
    end

    defp replace_bits_with_data_bits(zipper) do
      node = Sourceror.Zipper.node(zipper)
      source = Sourceror.to_string(node)

      # Replace bits: N with time_bits: 0, data_bits: N
      updated_source =
        Regex.replace(~r/\bbits:\s*(\d+)/, source, "time_bits: 0, data_bits: \\1")

      {:ok, updated_node} = Sourceror.parse_string(updated_source)
      Sourceror.Zipper.replace(zipper, updated_node)
    end
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
