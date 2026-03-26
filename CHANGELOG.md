# Changelog

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
