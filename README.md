# AshFeistelCipher

AshFeistelCipher is an `Ash.Resource` extension for transforming integer attribute values using a Feistel cipher. This enables the generation of non-sequential, unpredictable values from sequential or otherwise predictable integer inputs.

## Installation

```
mix igniter.install ash_feistel_cipher
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
    encrypt do
      source :seq # Source attribute for the Feistel cipher.
      target :id # Target attribute for the Feistel cipher.
      bits 40 # Specifies the maximum number of bits for both the source and target integers.
      bits_confirm "0x28" # A confirmation value to prevent unintentional changes to the 'bits' setting.
    end

    encrypt do
      # You can define multiple 'encrypt' blocks if you need to configure
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