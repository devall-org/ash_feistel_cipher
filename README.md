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
    # Option 1: Use convenience helpers (recommended for clarity)
    integer_sequence :seq
    feistel_cipher_target :id, primary_key?: true, allow_nil?: false
    feistel_cipher_target :referral_code, allow_nil?: false
    
    # Option 2: Use regular attributes (equivalent to Option 1)
    # attribute :seq, :integer, writable?: false, generated?: true
    # attribute :id, :integer, writable?: false, generated?: true, primary_key?: true, allow_nil?: false
    # attribute :referral_code, :integer, writable?: false, generated?: true, allow_nil?: false
    
    # Option 3: Use nullable columns
    # integer_sequence :optional_seq, allow_nil?: true
    # feistel_cipher_target :optional_id, allow_nil?: true
    
    # Option 4: Use any integer attribute as source (not just integer_sequence)
    # attribute :custom_seq, :integer, allow_nil?: false
    # feistel_cipher_target :custom_id, allow_nil?: false
  end

  feistel_cipher do
    functions_prefix "accounts" # PostgreSQL schema where feistel functions are installed. Default is "public".
    
    encrypt do
      source :seq # Source can be any integer attribute (integer_sequence or regular integer)
      target :id # Target attribute for the encrypted value
      bits 40 # Specifies the maximum number of bits for both the source and target integers.
    end

    encrypt do
      source :seq # Multiple encrypts can share the same source
      target :referral_code
      key 12345 # Custom encryption key (0 to 2^31-1) or derive automatically from attributes.
    end
  end
end
```

### Understanding Source Attributes

The `source` in an `encrypt` block can be **any integer attribute**:

- **`integer_sequence`**: A convenience utility that declares an auto-generated bigserial column (similar to `AUTO_INCREMENT` or `SERIAL`). While the value is auto-generated on insert, you can specify `allow_nil?: true` if you need to allow updates that set the value to nil.
- **Regular integer attributes**: You can use any integer attribute as the source, whether it's manually assigned or generated through other means. The attribute just needs to be of type `:integer`. **Both nullable (`allow_nil?: true`) and non-nullable columns are supported**.

Example with custom source:
```elixir
attributes do
  # Non-nullable source
  attribute :my_number, :integer, allow_nil?: false
  feistel_cipher_target :encrypted_number, allow_nil?: false
  
  # Nullable source
  attribute :optional_number, :integer, allow_nil?: true
  feistel_cipher_target :optional_encrypted, allow_nil?: true
end

feistel_cipher do
  encrypt do
    source :my_number
    target :encrypted_number
  end
  
  encrypt do
    source :optional_number
    target :optional_encrypted
  end
end
```

Then,

```
mix ash.codegen create_post
```

will generate a migration that sets up a database trigger to encrypt the `seq` attribute into the `id` attribute using a Feistel cipher.

### Key Concepts

- **`integer_sequence`**: A convenience helper that creates an auto-incrementing bigserial column (equivalent to `attribute :name, :integer, writable?: false, generated?: true`). Use this when you want a sequential source column that automatically increments. You can also use a regular `attribute :name, :integer` instead.

- **`feistel_cipher_target`**: A convenience helper that creates an integer column with `writable?: false` and `generated?: true` (equivalent to `attribute :name, :integer, writable?: false, generated?: true`). Use this for encrypted output columns. You should set `allow_nil?` to match your source attribute's nullability. **Important**: When you use `feistel_cipher_target`, you must add a corresponding `encrypt` block - otherwise you'll get a compilation error. You can also use a regular `attribute :name, :integer, writable?: false, generated?: true` instead.

- **Using regular `attribute` instead of helpers**: Both `integer_sequence` and `feistel_cipher_target` are just convenience helpers. You can use regular `attribute` declarations instead:
  ```elixir
  # Using helpers (recommended for clarity)
  integer_sequence :seq
  feistel_cipher_target :id, primary_key?: true, allow_nil?: false
  
  # Equivalent with regular attributes
  attribute :seq, :integer, writable?: false, generated?: true
  attribute :id, :integer, writable?: false, generated?: true, primary_key?: true, allow_nil?: false
  ```

- **Nullable columns**: Both source and target attributes support `allow_nil?: true`. When your source allows nil, the target should also allow nil.

- **`source` in `encrypt` block**: Can be any integer attribute - not limited to `integer_sequence`. You can use any integer column as the source for encryption.

- **Multiple encrypts from same source**: You can encrypt the same source value into multiple different targets with different encryption keys for different use cases (e.g., public IDs and referral codes).

### Validation

The library includes a verifier that ensures every `feistel_cipher_target` attribute has a corresponding `encrypt` configuration. This prevents the common mistake of declaring a target attribute but forgetting to configure its encryption:

```elixir
# ❌ This will raise a compilation error:
attributes do
  integer_sequence :seq
  feistel_cipher_target :id  # Missing encrypt configuration!
end

# ✅ This is correct:
attributes do
  integer_sequence :seq
  feistel_cipher_target :id
end

feistel_cipher do
  encrypt do
    source :seq
    target :id
  end
end
```

## Related Projects

* [feistel_cipher](https://github.com/devall-org/feistel_cipher): The underlying library that provides Ecto migrations and PostgreSQL functions for Feistel cipher operations. `ash_feistel_cipher` builds on top of this to integrate the capability seamlessly into the Ash framework.

## License

MIT