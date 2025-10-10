# AshFeistelCipher

AshFeistelCipher is an `Ash.Resource` extension for transforming integer attribute values using a Feistel cipher. This enables the generation of non-sequential, unpredictable values from sequential or otherwise predictable integer inputs.

## Installation

### Using igniter (Recommended)

```bash
mix igniter.install ash_feistel_cipher
```

You can customize the installation with the following options:

* `--repo` or `-r`: Specify an Ecto repo for FeistelCipher to use.
* `--functions-prefix` or `-p`: Specify the PostgreSQL schema prefix where the FeistelCipher functions will be created, defaults to `public`.
* `--functions-salt` or `-s`: Specify the constant value used in the Feistel cipher algorithm. Changing this value will result in different cipher outputs for the same input, should be less than 2^31, defaults to `1_076_943_109`.

Example with custom options:

```bash
mix igniter.install ash_feistel_cipher --functions-prefix accounts --functions-salt 123456789
```

### Manual Installation

If you need more control over the installation process, you can install manually:

1. Add `ash_feistel_cipher` to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [
       {:ash_feistel_cipher, "~> 0.7.0"}
     ]
   end
   ```

2. Fetch the dependencies:

   ```bash
   mix deps.get
   ```

3. Install FeistelCipher separately with custom options if needed:

   ```bash
   mix igniter.install feistel_cipher --repo MyApp.Repo --functions-prefix accounts
   ```

4. Add `:ash_feistel_cipher` to your formatter configuration in `.formatter.exs`:

   ```elixir
   [
     import_deps: [:ash_feistel_cipher]
   ]
   ```

## Usage

Use `AshFeistelCipher` in your `Ash.Resource` and configure the `feistel_cipher` block as follows:

```elixir
defmodule MyApp.Post do
  use Ash.Resource,
    data_layer: Ash.DataLayer.Postgres,
    extensions: [AshFeistelCipher]

  attributes do
    integer_primary_key :id

    # 'seq' is only a source for generating serial integers, so override with primary_key?: false.
    integer_primary_key :seq, primary_key?: false
  end

  feistel_cipher do
    functions_prefix "accounts" # PostgreSQL schema where feistel functions are installed. Default is "public".
    
    encrypt do
      source :seq # Source attribute for the Feistel cipher.
      target :id # Target attribute for the Feistel cipher.
      bits 40 # Specifies the maximum number of bits for both the source and target integers.
    end

    encrypt do
      source :seq
      target :referral_code
      key 12345 # Custom encryption key. Generate with FeistelCipher.random_key() or derive automatically.
    end
  end
end
```

Then,

```
mix ash.codegen create_post
```

will generate a migration that sets up a database trigger to encrypt the `seq` attribute into the `id` attribute using a Feistel cipher.

## See Also

* [feistel_cipher](https://github.com/devall-org/feistel_cipher): Provides Ecto migrations for Feistel cipher. `ash_feistel_cipher` integrates this capability into the Ash framework for easy use with Ash resources.

## License

MIT