# Upgrading AshFeistelCipher

## From v0.14.0 or v0.15.0 to v1.0.0

### What changed

- **`bits` option renamed to `data_bits`** (default changed from 52 to 40)
- **New DSL options**: `time_bits` (default: 12), `time_bucket` (default: 86400), `encrypt_time` (default: false)
- **Depends on `feistel_cipher ~> 1.0`** (PG functions use `_v1` suffix)

### Steps

1. **Update source code** — replace `bits:` with `time_bits: 0, data_bits:` in your Ash resources:

```elixir
# Before (v0.x)
encrypted_integer_primary_key :id, from: :seq, bits: 52

# After (v1.0)
encrypted_integer_primary_key :id, from: :seq, time_bits: 0, data_bits: 52
```

If `bits` was not specified (default was 52), add `time_bits: 0, data_bits: 52` explicitly.

> **Note**: The project won't compile until all `bits:` usages are replaced, because `bits:` is no longer a valid option in v1.0.

2. **Upgrade database** — generate the migration for upgrading PostgreSQL functions:

```bash
mix ash_feistel_cipher.upgrade
```

This composes `feistel_cipher.upgrade` to generate an Ecto migration template. Edit the generated migration to fill in your `functions_salt` and trigger details. See [feistel_cipher UPGRADE.md](https://github.com/devall-org/feistel_cipher/blob/main/UPGRADE.md) for details.

3. **Regenerate Ash migrations**:

```bash
mix ash.codegen --name upgrade_feistel_v1
```

In the generated migration's `up` function, replace `down_for_trigger` (or `down_for_v1_trigger`) with `force_down_for_legacy_trigger` to drop legacy triggers. Also in the `down` function, replace `up_for_trigger` with `up_for_legacy_trigger` and `bits:` with `time_bits: 0, data_bits:`.

---

## From v0.13.x or earlier to v1.0.0

The `feistel_cipher` dependency changed its cipher algorithm in v0.14.0 (HMAC-SHA256 hardening), so encryption results are different from v0.13.x and earlier. See [feistel_cipher UPGRADE.md](https://github.com/devall-org/feistel_cipher/blob/main/UPGRADE.md#from-v013x-or-earlier-to-v100) for details on compatibility.

The DSL upgrade steps are the same as above.
