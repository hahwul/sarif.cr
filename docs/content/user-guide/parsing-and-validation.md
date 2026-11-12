+++
title = "Parsing & Validation"
description = "Read existing SARIF files and validate them against the specification."
weight = 4
+++

sarif.cr can read existing SARIF JSON and validate documents against the specification.

## Parsing SARIF JSON

Parse a JSON string into a `SarifLog`:

```crystal
json = File.read("results.sarif")
log = Sarif.parse(json)

log.runs.try &.each do |run|
  puts "Tool: #{run.tool.driver.name}"
  run.results.try &.each do |result|
    puts "  #{result.level}: #{result.message.text}"
  end
end
```

## Reading from a File

Use the convenience method to read and parse in one step:

```crystal
log = Sarif.from_file("results.sarif")
```

## Parsing with Validation

Use `parse!` or `from_file!` to parse and validate in one step. These raise an exception if validation fails:

```crystal
begin
  log = Sarif.parse!(json)
rescue ex
  puts "Invalid SARIF: #{ex.message}"
end
```

```crystal
begin
  log = Sarif.from_file!("results.sarif")
rescue ex
  puts "Invalid SARIF: #{ex.message}"
end
```

## Manual Validation

Run validation separately using `Sarif::Validator`:

```crystal
log = Sarif.parse(json)
result = Sarif::Validator.new.validate(log)

if result.valid?
  puts "Valid SARIF document"
else
  result.errors.each do |error|
    puts "#{error.path}: #{error.message}"
  end
end
```

## Validator Options

The validator accepts options to prevent resource exhaustion (DoS protection):

```crystal
validator = Sarif::Validator.new(
  max_runs: 10,       # maximum number of runs allowed
  max_results: 5000,  # maximum results per run
  max_depth: 50       # maximum nesting depth (default: 100)
)

result = validator.validate(log)
```

The parser also supports a `max_size` option to reject oversized inputs before JSON parsing:

```crystal
log = Sarif.parse(json, max_size: 10_000_000)          # 10 MB limit
log = Sarif.from_file("results.sarif", max_size: 10_000_000)
```

## Validation Checks

The validator checks for:

- **Version** -- Must be `"2.1.0"`
- **Tool driver name** -- Must not be empty
- **Result message** -- Must have either `text` or `id`
- **Message arguments** -- A `{n}` placeholder in `text`, `markdown` or the string `id` looks up (the rule's or notification descriptor's `messageStrings`, then the component's `globalMessageStrings`) needs at least n+1 `arguments`; `{{` and `}}` are escaped braces (§3.11.5, §3.11.11)
- **Rule index** -- `ruleIndex` (or `rule.index`) must reference a valid rule in the tool component named by `rule.toolComponent` (the driver by default)
- **Rule ID consistency** -- `ruleId` (or `rule.id`) must match the rule at that index
- **Descriptor references** -- `rule`, `taxa`, notification `descriptor`/`associatedRule`, configuration override `descriptor` and rule relationship `target` must carry at least one of `index`, `guid` or `id`
- **Kind and level** -- `level` must be `none` when `kind` is not `fail`
- **GUID format** -- Must be an RFC 4122 UUID (version 1-5, variant `8`/`9`/`a`/`b`), as in the official schema
- **Timestamp format** -- Must be RFC 3339
- **URI format** -- Must be absolute URI
- **Result rank** -- Must be 0.0–100.0, or -1.0 (unknown)
- **Occurrence count** -- Must be >= 1
- **Code flow** -- Must have at least one thread flow
- **Thread flow** -- Must have at least one location
- **Fix** -- Must have at least one artifact change
- **Artifact change** -- Must have at least one replacement
- **Artifact length** -- Must be >= -1
- **Index-like values** -- `location.id`, thread flow location `index`/`executionOrder` must be >= -1; `nestingLevel` and relationship `target` must be >= 0
- **originalUriBaseIds** -- A relative `uri` needs a `uriBaseId` and an absolute one must not have one; each `uri` ends with `/` and has no query, fragment or `..` segment; `uriBaseId` chains must not loop (§3.14.14)
- **Invocation time** -- `endTimeUtc` must be >= `startTimeUtc`
- **Nesting depth** -- Must not exceed `max_depth`

## Working with Parsed Data

After parsing, you can navigate the full object graph:

```crystal
log = Sarif.from_file("eslint-results.sarif")
run = log.runs![0]

# Access tool info
puts run.tool.driver.name      # => "ESLint"
puts run.tool.driver.version   # => "8.0.0"

# Access rules
run.tool.driver.rules.try &.each do |rule|
  puts "#{rule.id}: #{rule.short_description.try &.text}"
end

# Access results
run.results.try &.each do |result|
  loc = result.locations.try &.[0]?
  if phys = loc.try &.physical_location
    uri = phys.artifact_location.try &.uri
    line = phys.region.try &.start_line
    puts "#{uri}:#{line} - #{result.message.text}"
  end
end
```

## Lightweight Validation

Each core model provides a `valid?` method for quick structural checks without the full Validator:

```crystal
message = Sarif::Message.new(text: "Issue found")
message.valid?  # => true (has text)

result = Sarif::Result.new(message: message)
result.valid?   # => true (checks message, rank 0-100 or -1, occurrence_count >= 1)

run = Sarif::Run.new(tool: Sarif::Tool.new(driver: driver))
run.valid?      # => true (checks driver name and all results)

log = Sarif::SarifLog.new(runs: [run])
log.valid?      # => true (checks version "2.1.0" and all runs)
```

## Error Types

sarif.cr defines structured error types for different failure scenarios:

| Type | Description |
|------|-------------|
| `Sarif::Error` | Base exception class |
| `Sarif::ValidationError` | A single validation error with a JSONPath-like `path` |
| `Sarif::ParseError` | Raised by `parse!` / `from_file!` when validation fails |
| `Sarif::ValidationResult` | Result object with `valid?` and `errors` |

### Handling Parse Errors

```crystal
begin
  log = Sarif.parse!(json)
rescue ex : Sarif::ParseError
  ex.validation_errors.each do |error|
    puts "#{error.path}: #{error.message}"
    # $.version: Unsupported SARIF version: 1.0. Expected 2.1.0
    # $.runs[0].tool.driver.name: Tool driver name must not be empty
  end
rescue ex : JSON::ParseException
  puts "Malformed JSON: #{ex.message}"
end
```

### Working with Validation Results

```crystal
result = Sarif::Validator.new.validate(log)

unless result.valid?
  result.errors.each do |error|
    puts "#{error.path}: #{error.message}"
  end
end
```
