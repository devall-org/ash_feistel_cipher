# Rules for working with AshFeistelCipher

## Overview

AshFeistelCipher encrypts sequential integer IDs using Feistel cipher to prevent business information leakage. It handles encryption automatically via PostgreSQL database triggers.

**Database Support**: PostgreSQL only (requires AshPostgres data layer)

## Installation

Recommended using igniter:
```bash
mix igniter.install ash_feistel_cipher
```

Key options:
- `--repo` or `-r`: Specify Ecto repo
- `--functions-prefix` or `-p`: PostgreSQL schema for functions (default: `public`)
- `--functions-salt` or `-s`: Feistel cipher salt (default: randomly generated)

⚠️ **Security Note**: A unique salt is automatically generated per project. Never use the same salt across multiple production projects.

## Basic Usage

### Simple Primary Key Encryption

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
  end
end
```

Generate migration:
```bash
mix ash.codegen create_post
```

### Multiple Encrypted Columns

Create multiple encrypted columns from the same source (each uses different key):

```elixir
attributes do
  integer_sequence :seq
  encrypted_integer_primary_key :id, from: :seq
  encrypted_integer :referral_code, from: :seq, allow_nil?: false
end
```

### Optional Integer Encryption

Nullable integer attributes can also be encrypted:

```elixir
attributes do
  attribute :postal_code, :integer, allow_nil?: true
  encrypted_integer :encrypted_postal_code, from: :postal_code, allow_nil?: true
end
```

## DSL Reference

### `integer_sequence`

Declares an auto-incrementing bigserial column:
```elixir
integer_sequence :seq
```

### `encrypted_integer`

Encrypted integer column (automatically sets `writable?: false`, `generated?: true`):
```elixir
encrypted_integer :id, from: :seq, primary_key?: true
encrypted_integer :referral_code, from: :seq, key: 12345
```

### `encrypted_integer_primary_key`

Shorthand for primary keys (automatically sets `primary_key?: true`, `allow_nil?: false`, `public?: true`):
```elixir
encrypted_integer_primary_key :id, from: :seq
encrypted_integer_primary_key :id, from: :seq, bits: 40
```

## Configuration Options

### Required
- `from`: Integer attribute to encrypt (required)

### Optional
⚠️ **Treat changes as explicit migrations**:
- `bits` (default: 52): Encryption bit size. Determines ID range (40 bits = ~1 trillion, 52 bits = ~4.5 quadrillion)
- `key`: Encryption key (auto-generated from table/column names if not provided)
- `rounds` (default: 16): Number of Feistel rounds (higher = more secure but slower)
- `functions_prefix` (default: "public"): PostgreSQL schema where feistel functions are installed

### Custom Bit Size Example

```elixir
encrypted_integer_primary_key :id, 
  from: :seq,
  bits: 40  # ~1 trillion ID range
```

## Important Rules

### Nullability Consistency

The encrypted column's `allow_nil?` must match the source attribute:

```elixir
# CORRECT
attribute :postal_code, :integer, allow_nil?: true
encrypted_integer :encrypted_postal_code, from: :postal_code, allow_nil?: true

# WRONG - will fail verification
attribute :postal_code, :integer, allow_nil?: true
encrypted_integer :encrypted_postal_code, from: :postal_code, allow_nil?: false
```

### Source Attribute Must Exist

The attribute specified in `from` must be defined:

```elixir
# WRONG - :seq not defined
attributes do
  encrypted_integer_primary_key :id, from: :seq  # Error!
end

# CORRECT
attributes do
  integer_sequence :seq
  encrypted_integer_primary_key :id, from: :seq
end
```

### Migration Required For Parameter Changes

These options should be treated as immutable in-place once records exist:
- `bits`
- `key`
- `rounds`

Changing them requires data migration.

## How It Works

Database triggers handle encryption automatically:

```elixir
post = MyApp.Post.create!(%{title: "Hello"})
# => %MyApp.Post{seq: 1, id: 3_141_592_653, ...}

post2 = MyApp.Post.create!(%{title: "World"})
# => %MyApp.Post{seq: 2, id: 2_718_281_828, ...}
```

- Sequential `seq` → Non-sequential `id` via automatic encryption
- Deterministic (same seq always produces same id)
- Collision-free (one-to-one mapping)

## Migration

`mix ash.codegen` automatically includes trigger creation code in migrations:

```elixir
def up do
  create table(:posts) do
    add :seq, :bigserial, null: false
    add :id, :bigint, null: false, primary_key: true
  end

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
```

## Testing

Use standard Ash testing patterns:

```elixir
test "encrypted IDs are generated" do
  post = MyApp.Domain.create_post!(%{title: "Test"})
  
  assert post.id != post.seq
  assert post.id > 0
  
  # Deterministic - same seq always produces same id
  post2 = MyApp.Domain.create_post!(%{title: "Test2"})
  assert post.id != post2.id
end
```

## Common Pitfalls

### Using UUID Instead

If you need UUIDs, use Ash's built-in `uuid_primary_key`:

```elixir
# Use Feistel for integer IDs
encrypted_integer_primary_key :id, from: :seq

# Use UUID for random IDs
uuid_primary_key :id
```

### Exposing Sequential IDs

Don't expose sequential IDs directly:

```elixir
# BAD - exposes sequential pattern
%{id: post.seq}

# GOOD - use encrypted ID
%{id: post.id}
```

### Changing Encryption Settings

Cannot change `bits`, `key`, `rounds` after records are created. Requires data migration to change.
