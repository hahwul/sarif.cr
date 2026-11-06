# Changelog

## Unreleased

### Breaking changes

- `SarifLog#runs` is now `Array(Run)?` (was `Array(Run)`), and `SarifLog.new(runs:)` accepts `nil`. SARIF 2.1.0 §3.13.4 allows `"runs": null` when the tool failed to start; such logs now parse and round-trip as `"runs": null` (the key is always emitted). A missing `runs` key is still rejected. Migrate `log.runs[0]` to `log.runs![0]` (raises `Sarif::Error` on null) or `log.runs.try &.each`. Query helpers (`all_results`, `find_results`, ...), `valid?` and `Validator` treat null runs as empty.
- `Region#byte_offset`, `#byte_length`, `#char_offset`, `#char_length` and `Artifact#offset` are now `Int64?` (were `Int32?`) so files larger than 2 GiB can be described. Integer literals still autocast; `Int32` variables passed to these setters/constructors need `.to_i64`.

### Added

- `SarifLog#runs!`.

### Fixed

- A leading UTF-8 byte order mark is ignored by `Sarif.parse`, `Sarif.from_file` and `SarifLog.from_json`, including IOs that deliver it across short reads (RFC 8259 §8.1). Output never contains a BOM.
- `Validator` rejects a negative `artifact.offset` (schema `minimum: 0`).

## v0.2.0

### Added

- Expand Validator to cover more SARIF 2.1.0 constraints (GUID, timestamps, URI, rank range, occurrence count, code flow, thread flow, fix, artifact, etc.)
- Add model-level `valid?` methods to `Message`, `Result`, `Run`, and `SarifLog` for lightweight validation without the full Validator
- Add input size and array limits (`max_size`, `max_runs`, `max_results`) to prevent DoS
- Extend Builder with `CodeFlow`, `Fix`, and `Suppression` DSL support
- Add query and filtering helpers to `Run` and `SarifLog` (`find_results`, `result_counts_by_level`, `result_counts_by_rule_id`, `find_locations_in_file`)
- Add edge case tests for parser, builder, and `PropertyBag`
- Add doc comments with SARIF spec references to core public classes and methods
- Improve `PropertyBag` type safety with typed accessors (`get_string`, `get_int`, `get_float`, `get_bool`) and utilities (`has_key?`, `size`, `keys`, `merge!`)
- Add `max_depth` option to Validator for DoS protection against deep nesting
- Add unit tests for 25+ previously untested SARIF data model classes (185 → 312 tests)

### Changed

- Extract `Error`, `ValidationError`, `ParseError`, `ValidationResult` into `errors.cr`
- Unify JSON exception wrapping across all parse methods
- Consolidate `ruleId`/`ruleIndex` cross-validation into single if/elsif chain

## v0.1.0

- Initial release
