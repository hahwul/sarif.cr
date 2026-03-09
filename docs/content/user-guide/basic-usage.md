+++
title = "Basic Usage"
description = "Create and manipulate SARIF objects directly using the Crystal type system."
weight = 2
+++

This guide covers working with SARIF objects directly. Each SARIF type maps to a Crystal class with typed properties and JSON serialization.

## Creating Results

A `Result` is the core finding object. At minimum, it requires a `Message`:

```crystal
result = Sarif::Result.new(
  message: Sarif::Message.new(text: "Unused variable 'x'")
)
```

Add a rule reference and severity:

```crystal
result = Sarif::Result.new(
  message: Sarif::Message.new(text: "Unused variable 'x'"),
  rule_id: "LINT001",
  level: Sarif::Level::Warning
)
```

## Adding Locations

Specify where the issue was found:

```crystal
result = Sarif::Result.new(
  message: Sarif::Message.new(text: "SQL injection risk"),
  rule_id: "SEC001",
  level: Sarif::Level::Error,
  locations: [
    Sarif::Location.new(
      physical_location: Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(
          uri: "src/controllers/user_controller.cr",
          uri_base_id: "%SRCROOT%"
        ),
        region: Sarif::Region.new(
          start_line: 42,
          start_column: 10,
          end_line: 42,
          end_column: 55
        )
      )
    ),
  ]
)
```

## Defining Rules

Rules are defined on the tool's driver component:

```crystal
driver = Sarif::ToolComponent.new(
  name: "SecurityScanner",
  version: "2.0.0",
  rules: [
    Sarif::ReportingDescriptor.new(
      id: "SEC001",
      name: "SqlInjection",
      short_description: Sarif::MultiformatMessageString.new(
        text: "SQL Injection vulnerability"
      ),
      help_uri: "https://example.com/rules/SEC001",
      default_configuration: Sarif::ReportingConfiguration.new(
        level: Sarif::Level::Error
      )
    ),
  ]
)
```

## Assembling a Complete Document

Combine tool, results, and other metadata into a `SarifLog`:

```crystal
log = Sarif::SarifLog.new(
  runs: [
    Sarif::Run.new(
      tool: Sarif::Tool.new(driver: driver),
      results: [result],
      artifacts: [
        Sarif::Artifact.new(
          location: Sarif::ArtifactLocation.new(uri: "src/controllers/user_controller.cr"),
          mime_type: "text/x-crystal",
          roles: [Sarif::ArtifactRole::AnalysisTarget]
        ),
      ],
      column_kind: Sarif::ColumnKind::Utf16CodeUnits
    ),
  ]
)
```

## JSON Output

All SARIF types support `to_json` and `to_pretty_json`:

```crystal
puts log.to_json          # compact JSON
puts log.to_pretty_json   # indented JSON
```

Crystal's snake_case properties are automatically mapped to SARIF's camelCase keys. For example, `start_line` becomes `startLine` and `rule_id` becomes `ruleId`.

## Default Values

SARIF defines default values for some fields. sarif.cr keeps these as `nil` and provides `effective_*` methods:

```crystal
result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))

result.level              # => nil
result.effective_level    # => Sarif::Level::Warning (SARIF default)

result.kind               # => nil
result.effective_kind     # => Sarif::ResultKind::Fail (SARIF default)
```

## Nil Omission

Optional fields set to `nil` are omitted from JSON output. This produces clean, minimal SARIF:

```crystal
result = Sarif::Result.new(
  message: Sarif::Message.new(text: "test"),
  rule_id: "R1"
)
result.to_json
# => {"message":{"text":"test"},"ruleId":"R1"}
# No "level", "locations", "codeFlows", etc.
```
