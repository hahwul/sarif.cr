+++
title = "SarifLog"
description = "API reference for the top-level SarifLog class."
weight = 1
+++

The top-level object in a SARIF document. Every valid SARIF file is a single `SarifLog`.

## Constructor

```crystal
Sarif::SarifLog.new(
  runs : Array(Sarif::Run),
  version : String = "2.1.0",
  schema : String? = Sarif::SARIF_SCHEMA,
  inline_external_properties : Array(Sarif::ExternalProperties)? = nil,
  properties : Sarif::PropertyBag? = nil
)
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `runs` | `Array(Run)` | Yes | The set of runs contained in this log |
| `version` | `String` | Yes | SARIF version, defaults to `"2.1.0"` |
| `schema` | `String?` | No | JSON schema URI |
| `inline_external_properties` | `Array(ExternalProperties)?` | No | Inline external property collections |
| `properties` | `PropertyBag?` | No | Custom properties |

## Properties

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `version` | `String` | `version` | SARIF specification version |
| `schema` | `String?` | `$schema` | JSON schema URI for validation |
| `runs` | `Array(Run)` | `runs` | Array of analysis runs |
| `inline_external_properties` | `Array(ExternalProperties)?` | `inlineExternalProperties` | External property collections |
| `properties` | `PropertyBag?` | `properties` | Custom key-value pairs |

## Class Methods

### `.from_json`

```crystal
Sarif::SarifLog.from_json(json : String) : SarifLog
```

Deserializes a SARIF JSON string into a `SarifLog` object.

```crystal
log = Sarif::SarifLog.from_json(File.read("results.sarif"))
```

## Instance Methods

### `#to_json`

Serializes to compact JSON string.

```crystal
log.to_json
# => {"version":"2.1.0","$schema":"...","runs":[...]}
```

### `#to_pretty_json`

Serializes to indented JSON string.

```crystal
puts log.to_pretty_json
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `Sarif::SARIF_VERSION` | `"2.1.0"` | Current SARIF specification version |
| `Sarif::SARIF_SCHEMA` | `"https://docs.oasis-open.org/sarif/sarif/v2.1.0/cos02/schemas/sarif-schema-2.1.0.json"` | Official JSON schema URI |

## Example

```crystal
log = Sarif::SarifLog.new(
  runs: [
    Sarif::Run.new(
      tool: Sarif::Tool.new(
        driver: Sarif::ToolComponent.new(name: "MyTool")
      )
    ),
  ]
)

puts log.to_pretty_json
```

## Module-Level Parse Methods

The `Sarif` module provides convenience methods:

```crystal
Sarif.parse(json : String) : SarifLog     # Parse JSON string
Sarif.from_file(path : String) : SarifLog  # Read and parse file
Sarif.parse!(json : String) : SarifLog     # Parse with validation
Sarif.from_file!(path : String) : SarifLog # Read, parse, and validate
```
