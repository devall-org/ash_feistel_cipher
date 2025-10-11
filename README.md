# AshFeistelCipher

Unpredictable integer IDs for Ash resources - UUID alternative using Feistel cipher

## Overview

Sequential IDs (1, 2, 3...) leak business information. This library provides a declarative DSL to configure [Feistel cipher](https://github.com/devall-org/feistel_cipher) encryption in your Ash resources, transforming sequential integers into non-sequential, unpredictable values automatically via database triggers.

**Key Benefits:**
- **No UUIDs needed**: Keep efficient integer IDs (stored as bigint) with configurable ID ranges per column
- **Ash-native**: Declarative configuration using Ash resource DSL
- **Automatic encryption**: Database triggers handle encryption transparently
- **Collision-free**: Deterministic one-to-one mapping

> For detailed information about the Feistel cipher algorithm, how it works, security properties, and performance benchmarks, see the [feistel_cipher](https://github.com/devall-org/feistel_cipher) library documentation.

## Installation

### Using igniter (Recommended)

```bash
mix igniter.install ash_feistel_cipher
```

You can customize the installation with the following options:

* `--repo` or `-r`: Specify an Ecto repo for FeistelCipher to use.
* `--functions-salt` or `-s`: Specify the constant value used in the Feistel cipher algorithm. Changing this value will result in different cipher outputs for the same input, should be less than 2^31, defaults to `1_076_943_109`.

Example with custom salt:

```bash
mix igniter.install ash_feistel_cipher --functions-salt 123456789
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

3. Install FeistelCipher separately:

   ```bash
   mix igniter.install feistel_cipher --repo MyApp.Repo
   ```

4. Add `:ash_feistel_cipher` to your formatter configuration in `.formatter.exs`:

   ```elixir
   [
     import_deps: [:ash_feistel_cipher]
   ]
   ```

## Usage

### Quick Start

Add `AshFeistelCipher` extension to your Ash resource and use the declarative DSL:

```elixir
defmodule MyApp.Post do
  use Ash.Resource,
    data_layer: Ash.DataLayer.Postgres,
    extensions: [AshFeistelCipher]

  attributes do
    integer_sequence :seq
    encrypted_integer_primary_key :id, from: :seq  # Convenience shorthand!
    
    attribute :title, :string, allow_nil?: false
    timestamps()
  end
end
```

Generate the migration:
```bash
mix ash.codegen create_post
```

This creates a migration with database triggers that automatically encrypt `seq` into `id`.

### Advanced Examples

**Multiple encrypted fields from same source:**
```elixir
attributes do
  integer_sequence :seq
  encrypted_integer_primary_key :id, from: :seq
  encrypted_integer :referral_code, from: :seq, key: 12345  # Different key for referral codes
end
```

**Custom encryption parameters:**
```elixir
attributes do
  integer_sequence :seq
  encrypted_integer :id, 
    from: :seq,
    bits: 40,     # Encryption bit size - determines ID range (default: 52)
    rounds: 8     # Feistel rounds (default: 16)
end
```

**Using any integer attribute as source:**
```elixir
attributes do
  attribute :custom_number, :integer
  encrypted_integer :encrypted_number, from: :custom_number
end
```

**Nullable columns:**
```elixir
attributes do
  integer_sequence :optional_seq, allow_nil?: true
  encrypted_integer :optional_id, from: :optional_seq, allow_nil?: true
end
```

### DSL Reference

**`integer_sequence`**: Auto-incrementing bigserial column
```elixir
integer_sequence :seq                        # Non-nullable
integer_sequence :optional_seq, allow_nil?: true  # Nullable
```

**`encrypted_integer_primary_key`**: Encrypted integer primary key with automatic trigger (convenience shorthand)

This is a convenience macro that automatically sets:
- `primary_key?: true`
- `allow_nil?: false`
- `public?: true`
- `writable?: false`
- `generated?: true`

Required options:
- `from`: Source attribute name

Optional parameters:
- `bits` (default: 52): Encryption bit size - determines ID range (40 bits = ~1T IDs, 52 bits = ~4.5Q IDs)
- `key`: Custom encryption key for different outputs from same source
- `rounds` (default: 16): Number of Feistel rounds (more = more secure)
- `functions_prefix` (default: "public"): PostgreSQL schema where feistel functions are installed

Examples:
```elixir
encrypted_integer_primary_key :id, from: :seq
encrypted_integer_primary_key :id, from: :seq, bits: 40
encrypted_integer_primary_key :id, from: :seq, key: 12345, rounds: 8
```

**`encrypted_integer`**: Encrypted integer column with automatic trigger

Required options:
- `from`: Source attribute name

Optional parameters:
- `bits` (default: 52): Encryption bit size - determines ID range (40 bits = ~1T IDs, 52 bits = ~4.5Q IDs)
- `key`: Custom encryption key for different outputs from same source
- `rounds` (default: 16): Number of Feistel rounds (more = more secure)

**Important**: 
- `allow_nil?` on target must match source attribute's nullability
- The `from` option can reference any integer attribute, not just `integer_sequence`
- For primary keys, prefer `encrypted_integer_primary_key` for cleaner syntax

> **Note**: For detailed parameter explanations (bits, rounds, performance), see [feistel_cipher Trigger Options](https://github.com/devall-org/feistel_cipher#trigger-options).

## Related Projects

### [feistel_cipher](https://github.com/devall-org/feistel_cipher)

The underlying library that provides the core Feistel cipher implementation for Ecto. `ash_feistel_cipher` builds on top of `feistel_cipher` to provide Ash-native declarative configuration.

**Use `feistel_cipher` directly if you're:**
- Using plain Ecto without Ash Framework
- Need manual control over migrations and triggers

**Use `ash_feistel_cipher` if you're:**
- Using Ash Framework
- Want declarative DSL configuration in Ash resources
- Prefer automatic migration generation via `mix ash.codegen`

For technical details about the algorithm, security properties, and performance benchmarks, see the [`feistel_cipher` documentation](https://github.com/devall-org/feistel_cipher).

## License

MIT