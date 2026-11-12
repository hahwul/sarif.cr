# Changelog

## Unreleased

### Breaking changes

- `SarifLog#runs` is now `Array(Run)?` (was `Array(Run)`), and `SarifLog.new(runs:)` accepts `nil`. SARIF 2.1.0 §3.13.4 allows `"runs": null` when the tool failed to start; such logs now parse and round-trip as `"runs": null` (the key is always emitted). A missing `runs` key is still rejected. Migrate `log.runs[0]` to `log.runs![0]` (raises `Sarif::Error` on null) or `log.runs.try &.each`. Query helpers (`all_results`, `find_results`, ...), `valid?` and `Validator` treat null runs as empty.
- `Run#resolve_rule_reference` no longer looks descriptors up by `id`. It now resolves only by `index`, then `guid`, within the `toolComponent` (§3.52.3). `id` does not take part in the lookup (§3.52.4 NOTE), and an id-only reference has no descriptor (§3.52.1), so such a reference now returns `nil`. `Result#resolve_rule`, `#effective_level` and configuration-override matching keep their id-based fallback (`rule.id`/`ruleId`, exact then hierarchical, within the referenced component), which is now documented as a consumer convenience. Callers of `resolve_rule_reference` that relied on id lookup should call `Result#resolve_rule` or `ToolComponent#find_rule`.
- `Region#byte_offset`, `#byte_length`, `#char_offset`, `#char_length` and `Artifact#offset` are now `Int64?` (were `Int32?`) so files larger than 2 GiB can be described. Integer literals still autocast; `Int32` variables passed to these setters/constructors need `.to_i64`.

### Added

- `SarifLog#runs!`.
- `Run#resolve_notification_reference` (§3.52.3 lookup within `notifications`).
- `Result#effective_rule_id` (`ruleId`, else `rule.id`).

### Fixed

- `Builder` always emits `results` on a run, as `[]` when nothing was added (§3.14.23). It used to drop the empty array, and an absent `results` means null: "the tool failed to start". Callers that tested `run.results.nil?` to detect a clean run should test `empty?`.
- `Sarif.parse(io, max_size:)` reads at most `max_size + 1` bytes. It used to read the whole IO before comparing it with the cap, so an endless or huge stream was buffered in full.
- `Sarif.with_strict_enums` is scoped to the calling fiber. It used to flip the process-wide flag, so another fiber parsing while the block waited on IO also became strict, and interleaved blocks could restore the wrong value. `Sarif.strict_enums=` still sets the process-wide default.
- `SarifLog#find_locations_in_file` matches an `artifactLocation` that names its file only through `index` into the run's `artifacts` (§3.4.2).
- `Validator` checks `run.originalUriBaseIds` (§3.14.14): a relative `uri` needs a `uriBaseId`, an absolute or absent one must not have one, a `uri` ends with `/` and has no query, fragment or `..` segment, and `uriBaseId` chains must not loop.
- `Validator` and the `valid?` helpers accept an explicit `rank: -1.0` on results and reporting configurations. The schema allows it (`minimum: -1.0`, the "unknown" default); other values outside 0.0-100.0 are still rejected.
- `Validator` checks the message argument count (§3.11.11): a `{n}` placeholder needs at least n+1 `arguments`. The check covers `text`, `markdown`, and the string `message.id` looks up in the rule's (or notification descriptor's) `messageStrings` or the component's `globalMessageStrings` when it resolves. `{{`/`}}` are escapes (§3.11.5). Result and notification messages are checked, and so are the nested location, region, codeFlow, threadFlow, stack, fix, graph, node, edge, graphTraversal, attachment, artifact and automationDetails messages.
- A leading UTF-8 byte order mark is ignored by `Sarif.parse`, `Sarif.from_file` and `SarifLog.from_json`, including IOs that deliver it across short reads (RFC 8259 §8.1). Output never contains a BOM.
- `Validator` rejects a negative `artifact.offset` (schema `minimum: 0`).
- `Sarif::GUID_PATTERN` (used by `Validator` and `ReportingDescriptor#valid?`) now requires the RFC 4122 version (1-5) and variant (8, 9, a, b) digits, the same pattern as the official schema (§3.5.3). GUIDs such as `22222222-2222-2222-2222-222222222222`, the nil UUID and v6-v8 UUIDs are now rejected.
- `results_by_rule_id`, `find_results(rule_id:)` and `result_counts_by_rule_id` on `Run` and `SarifLog` also match results that name their rule only through `rule.id` (§3.27.5).
- `Validator` false negatives: `rule.index`/`rule.id` are checked when `ruleIndex`/`ruleId` are absent (and both ids are checked against the descriptor); a `rule.toolComponent` that resolves to nothing is reported; every reportingDescriptorReference (`rule`, `taxa`, notification `descriptor`/`associatedRule`, configuration override `descriptor`, rule `relationships[].target`) needs `index`, `guid` or `id`; `level` must be `none` when `kind` is not `fail` (§3.27.10); `automationDetails`/`runAggregates` GUIDs, `deprecatedGuids`, `workItemUris`, `hostedViewerUri`, `location.id`, location relationship `target` and threadFlowLocation `index`/`nestingLevel`/`executionOrder` are checked against the schema.

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
