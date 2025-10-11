# AshFeistelCipher

Unpredictable integer IDs for Ash resources - no UUIDs needed 

## Why Use This?

**Problem**: Sequential IDs (1, 2, 3...) expose sensitive business information:
- Competitors can track your growth rate by checking IDs over time
- Users can enumerate all resources (`/posts/1`, `/posts/2`...)
- Total record counts are publicly visible

**Solution**: This library uses a [Feistel cipher](https://en.wikipedia.org/wiki/Feistel_cipher) to transform sequential integers into non-sequential, unpredictable values. You keep a sequential column for ordering, and an encrypted column as the primary key. Only the encrypted ID is exposed in APIs and URLs. The transformation is deterministic, collision-free, and automatically handled via database triggers integrated with Ash.

For more details on the algorithm and implementation, see [feistel_cipher](https://github.com/devall-org/feistel_cipher).

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
       {:ash_feistel_cipher, "~> 0.10.0"}
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
    attribute :id, :integer, allow_nil?: false, primary_key?: true
    attribute :referral_code, :integer

    feistel_cipher_source :seq
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
      key 12345 # Custom encryption key (0 to 2^31-1) or derive automatically from attributes.
    end
  end
end
```

Then,

```
mix ash.codegen create_post
```

will generate a migration that sets up a database trigger to encrypt the `seq` attribute into the `id` attribute using a Feistel cipher.

## Related Projects

* [feistel_cipher](https://github.com/devall-org/feistel_cipher): The underlying library that provides Ecto migrations and PostgreSQL functions for Feistel cipher operations. `ash_feistel_cipher` builds on top of this to integrate the capability seamlessly into the Ash framework.

## License

MIT