# AshFeistelCipher

Encrypted integer IDs for Ash resources using Feistel cipher

> **Database Support**: PostgreSQL only (requires AshPostgres data layer and PostgreSQL database)

## Overview

Sequential IDs (1, 2, 3...) leak business information. This library provides a declarative DSL to configure [Feistel cipher](https://github.com/devall-org/feistel_cipher) encryption in your Ash resources, transforming sequential integers into non-sequential, unpredictable values automatically via database triggers.

**Key Benefits:**
- **Secure IDs without UUIDs**: Hide sequential patterns while keeping efficient integer IDs (stored as bigint) with configurable ID ranges per column
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
* `--functions-prefix` or `-p`: Specify the PostgreSQL schema where the FeistelCipher functions will be created, defaults to `public`.
* `--functions-salt` or `-s`: Specify the constant value used in the Feistel cipher algorithm. Changing this value will result in different cipher outputs for the same input, should be less than 2^31, defaults to `1_076_943_109`.

### Manual Installation

If you need more control over the installation process, you can install manually:

1. Add `ash_feistel_cipher` to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [
       {:ash_feistel_cipher, "~> 0.12.1"}
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
    data_layer: AshPostgres.DataLayer,
    extensions: [AshFeistelCipher]

  postgres do
    table "posts"
    repo MyApp.Repo
  end

  attributes do
    integer_sequence :seq
    encrypted_integer_primary_key :id, from: :seq
    
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

**Generated Migration Example:**
```elixir
defmodule MyApp.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def up do
    create table(:posts) do
      add :seq, :bigserial, null: false
      add :id, :bigint, null: false, primary_key: true
      add :title, :string, null: false
      timestamps()
    end

    # Automatically generates trigger for seq -> id encryption
    execute(
      FeistelCipher.up_for_trigger("public", "posts", "seq", "id",
        bits: 52,
        key: 1_984_253_769,
        rounds: 16,
        functions_prefix: "public"
      )
    )
  end

  def down do
    execute(FeistelCipher.down_for_trigger("public", "posts", "seq", "id"))
    drop table(:posts)
  end
end
```

**How it works:**
When you create a record, the database trigger automatically encrypts the sequential `seq` value:

```elixir
# Create a post - only provide title, seq and id are auto-generated
post = MyApp.Post.create!(%{title: "Hello World"})
# => %MyApp.Post{seq: 1, id: 3_141_592_653, title: "Hello World"}

# The encrypted id is deterministic and collision-free
post2 = MyApp.Post.create!(%{title: "Second Post"})
# => %MyApp.Post{seq: 2, id: 2_718_281_828, title: "Second Post"}

# You can query by the encrypted id
MyApp.Post.get!(3_141_592_653)
# => %MyApp.Post{seq: 1, id: 3_141_592_653, title: "Hello World"}
```

### Advanced Examples

**Custom ID range with `bits`:**
```elixir
attributes do
  integer_sequence :seq
  encrypted_integer_primary_key :id, 
    from: :seq,
    bits: 40  # ~1 trillion IDs (default: 52 = ~4.5 quadrillion)
end
```

**Using any integer attribute with `from` (e.g. optional postal code):**
```elixir
attributes do
  attribute :postal_code, :integer, allow_nil?: true
  encrypted_integer :encrypted_postal_code, from: :postal_code, allow_nil?: true
end
```

### DSL Reference

**`integer_sequence`**: Auto-incrementing bigserial column
```elixir
integer_sequence :seq
```

**`encrypted_integer`**: Encrypted integer column

The base form for encrypted columns. Automatically sets `writable?: false`, `generated?: true`

```elixir
encrypted_integer :id, from: :seq, primary_key?: true, allow_nil?: false, public?: true
encrypted_integer :referral_code, from: :seq
```

**`encrypted_integer_primary_key`**: Shorthand for encrypted primary keys

Convenience macro equivalent to `encrypted_integer` with `primary_key?: true`, `allow_nil?: false`, `public?: true` pre-set.

```elixir
encrypted_integer_primary_key :id, from: :seq
encrypted_integer_primary_key :id, from: :seq, bits: 40
```

---

**Common Options for Encrypted Columns:**

Required:
- `from`: Integer attribute to encrypt (can be any integer attribute)

Optional (⚠️ **Cannot be changed after records are created**):
- `bits` (default: 52): Encryption bit size - determines ID range (40 bits = ~1T IDs, 52 bits = ~4.5Q IDs)
- `key`: Custom encryption key (auto-generated from table/column names if not provided)
- `rounds` (default: 16): Number of Feistel rounds (higher = more secure but slower)
- `functions_prefix` (default: "public"): PostgreSQL schema where feistel functions are installed (set via `--functions-prefix` during installation)

**Important**: 
- `allow_nil?` on encrypted column must match `from` attribute's nullability
- For primary keys, prefer `encrypted_integer_primary_key` for cleaner syntax

## License

MIT