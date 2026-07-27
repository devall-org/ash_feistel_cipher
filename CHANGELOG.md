# Changelog

## 1.1.2

- Moved the backfill sentinel from the Ash attribute `default` to ash_postgres `migration_defaults`.
- Encrypted attributes now keep a `nil` default, so `struct(Resource)` no longer carries a fake primary key (`-1`), which previously made `Ash.calculate/3` treat in-memory structs as persisted records.
- Generated snapshots and migrations are unchanged; no codegen churn.
- Requires `feistel_cipher ~> 1.1.2` for `FeistelCipher.backfill_sentinel/0`.

## 1.1.1

- Added the FeistelCipher major version to generated custom statement names.

## 1.1.0

- Added `backfill?` support for `encrypted_integer` and `encrypted_integer_primary_key`.
- Added migration backfill generation via `FeistelCipher.backfill_for_v1_column/5`.
- `encrypted_integer` now uses an internal sentinel default to avoid `bigserial` generation.
- User-provided `default:` is no longer supported for `encrypted_integer`.
- Generated custom statement names now include both `from` and `to`, which may cause migration and snapshot churn.

## 1.0.0

- Renamed `bits` to `data_bits`.
- Added `time_bits`, `time_bucket`, and `encrypt_time` options.
- Switched to `feistel_cipher` v1 PG function and trigger flow.
- Recommended new default profile: `time_bits: 15`, `data_bits: 38`.
