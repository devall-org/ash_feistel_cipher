# Changelog

## 1.0.0

- Renamed `bits` to `data_bits`.
- Added `time_bits`, `time_bucket`, and `encrypt_time` options.
- Switched to `feistel_cipher` v1 PG function and trigger flow.
- Recommended new default profile: `time_bits: 15`, `data_bits: 38`.

## 1.1.0

- Added `backfill?` support for `encrypted_integer` and `encrypted_integer_primary_key`.
- Added migration backfill generation via `FeistelCipher.backfill_for_v1_column/5`.
- `encrypted_integer` now uses an internal sentinel default to avoid `bigserial` generation.
- User-provided `default:` is no longer supported for `encrypted_integer`.
- Generated custom statement names now include both `from` and `to`, which may cause migration and snapshot churn.
