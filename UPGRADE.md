# Upgrading AshFeistelCipher

## From v0.14.0 or v0.15.0 to v1.0.0

### What changed

- **`bits` option renamed to `data_bits`** (default changed from 52 to 40)
- **New DSL options**: `time_bits` (default: 12), `time_bucket` (default: 86400), `encrypt_time` (default: false)
- **Depends on `feistel_cipher ~> 1.0`** (PG functions use `_v1` suffix)

### Steps

1. **Update source code** — run the upgrade task to update your Ash resource DSL:

```bash
mix ash_feistel_cipher.upgrade
```

This transforms `bits: N` → `time_bits: 0, data_bits: N` in your resource files. Setting `time_bits: 0` ensures backward compatibility with existing encrypted data.

2. **Upgrade database** — see [feistel_cipher UPGRADE.md](https://github.com/devall-org/feistel_cipher/blob/main/UPGRADE.md) for the database migration guide.

3. **Regenerate Ash migrations**:

```bash
mix ash.codegen upgrade_feistel_cipher
```

---

## From v0.13.x or earlier to v1.0.0

The `feistel_cipher` dependency changed its cipher algorithm in v0.14.0 (HMAC-SHA256 hardening), so encryption results are different from v0.13.x and earlier. See [feistel_cipher UPGRADE.md](https://github.com/devall-org/feistel_cipher/blob/main/UPGRADE.md#from-v013x-or-earlier-to-v100) for details on compatibility.

The DSL upgrade steps are the same as above.
