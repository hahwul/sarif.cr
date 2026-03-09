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

log.runs.each do |run|
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

## Validation Checks

The validator checks for:

- **Version** -- Must be `"2.1.0"`
- **Tool driver name** -- Must not be empty
- **Result message** -- Must have either `text` or `id`
- **Rule index** -- `ruleIndex` must reference a valid rule in the driver
- **Rule ID consistency** -- `ruleId` must match the rule at `ruleIndex`

## Working with Parsed Data

After parsing, you can navigate the full object graph:

```crystal
log = Sarif.from_file("eslint-results.sarif")
run = log.runs[0]

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

## Error Handling

JSON parsing errors from malformed input are raised as standard Crystal exceptions:

```crystal
begin
  log = Sarif.parse("invalid json")
rescue ex : JSON::ParseException
  puts "Malformed JSON: #{ex.message}"
end
```

Validation errors from structurally invalid SARIF are raised by the `!` variants:

```crystal
begin
  log = Sarif.parse!(%({ "version": "1.0", "runs": [] }))
rescue ex
  puts ex.message
  # => "SARIF validation failed: $.version: Unsupported SARIF version: 1.0. Expected 2.1.0"
end
```
