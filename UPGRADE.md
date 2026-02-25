# Upgrading AshFeistelCipher

## From v0.14.0 or v0.15.0 to v1.0.0

### What changed

- **`bits` option renamed to `data_bits`** (default changed from 52 to 40)
- **New DSL options**: `time_bits` (default: 12), `time_bucket` (default: 86400), `encrypt_time` (default: false)
- **Depends on `feistel_cipher ~> 1.0`** (PG functions use `_v1` suffix)

### Steps

1. **Update source code** -- replace `bits:` with `time_bits: 0, data_bits:` in your Ash resources:

```elixir
# Before (v0.x)
encrypted_integer_primary_key :id, from: :seq, bits: 52

# After (v1.0)
encrypted_integer_primary_key :id, from: :seq, time_bits: 0, data_bits: 52
```

If `bits` was not specified (default was 52), add `time_bits: 0, data_bits: 52` explicitly.

> **Note**: The project won't compile until all `bits:` usages are replaced, because `bits:` is no longer a valid option in v1.0.

2. **Generate function install migration**:

```bash
mix ash_feistel_cipher.upgrade
```

3. **Fill in `functions_salt`** in the generated migration. Find your original salt in the migration with timestamp `19730501000000`.

4. **Generate trigger migration** via Ash codegen:

```bash
mix ash.codegen --name upgrade_feistel_v1
```

5. **Fix the generated trigger migration**: In the generated migration, replace `down_for_trigger` with `force_down_for_trigger`. This is needed because the old trigger must be force-dropped before the new v1 trigger can be created.

6. **(Optional)** Add old function cleanup to the **last** migration. Which functions exist depends on the version you're upgrading from:

   ```elixir
   # v0.15.0
   execute "DROP FUNCTION IF EXISTS public.feistel_cipher(bigint, int, bigint, int)"
   execute "DROP FUNCTION IF EXISTS public.feistel_column_trigger()"

   # v0.14.0
   execute "DROP FUNCTION IF EXISTS public.feistel_encrypt(bigint, int, bigint, int)"
   execute "DROP FUNCTION IF EXISTS public.feistel_column_trigger()"

   # v0.13.x or earlier
   execute "DROP FUNCTION IF EXISTS public.feistel(bigint, int, bigint)"
   execute "DROP FUNCTION IF EXISTS public.handle_feistel_encryption()"
   ```

7. **Run migrations**:

```bash
mix ecto.migrate
```

---

## From v0.13.x or earlier to v1.0.0

The `feistel_cipher` dependency changed its cipher algorithm in v0.14.0 (HMAC-SHA256 hardening), so encryption results are different from v0.13.x and earlier. See [feistel_cipher UPGRADE.md](https://github.com/devall-org/feistel_cipher/blob/main/UPGRADE.md#from-v013x-or-earlier-to-v100) for details on compatibility.

The DSL upgrade steps are the same as above.
