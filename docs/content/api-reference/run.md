+++
title = "Run"
description = "API reference for the Run class and run-level types."
weight = 2
+++

A `Run` represents a single invocation of a single analysis tool. A `SarifLog` contains one or more runs.

## Constructor

```crystal
Sarif::Run.new(
  tool : Sarif::Tool,
  results : Array(Sarif::Result)? = nil,
  artifacts : Array(Sarif::Artifact)? = nil,
  invocations : Array(Sarif::Invocation)? = nil,
  # ... additional optional parameters
)
```

## Properties

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `tool` | `Tool` | `tool` | The analysis tool that produced this run |
| `results` | `Array(Result)?` | `results` | The results produced by the tool |
| `artifacts` | `Array(Artifact)?` | `artifacts` | Files relevant to the run |
| `invocations` | `Array(Invocation)?` | `invocations` | How the tool was invoked |
| `logical_locations` | `Array(LogicalLocation)?` | `logicalLocations` | Logical locations (namespaces, types, functions) |
| `graphs` | `Array(Graph)?` | `graphs` | Graphs associated with the run |
| `conversion` | `Conversion?` | `conversion` | Conversion details if results were converted |
| `language` | `String?` | `language` | Language of localizable strings (BCP-47) |
| `column_kind` | `ColumnKind?` | `columnKind` | How columns are counted |
| `automation_details` | `RunAutomationDetails?` | `automationDetails` | Run identification info |
| `version_control_provenance` | `Array(VersionControlDetails)?` | `versionControlProvenance` | Source control info |
| `original_uri_base_ids` | `Hash(String, ArtifactLocation)?` | `originalUriBaseIds` | URI base ID mappings |
| `default_encoding` | `String?` | `defaultEncoding` | Default file encoding |
| `default_source_language` | `String?` | `defaultSourceLanguage` | Default source language |
| `taxonomies` | `Array(ToolComponent)?` | `taxonomies` | Taxonomy definitions |
| `special_locations` | `SpecialLocations?` | `specialLocations` | Special location references |
| `properties` | `PropertyBag?` | `properties` | Custom properties |

## Related Types

### Invocation

Records how a tool was invoked.

```crystal
Sarif::Invocation.new(
  execution_successful: true,
  command_line: "linter --check src/",
  start_time_utc: "2024-01-15T10:30:00Z",
  end_time_utc: "2024-01-15T10:30:05Z",
  exit_code: 0
)
```

| Property | Type | JSON Key | Required |
|----------|------|----------|----------|
| `execution_successful` | `Bool` | `executionSuccessful` | Yes |
| `command_line` | `String?` | `commandLine` | No |
| `arguments` | `Array(String)?` | `arguments` | No |
| `start_time_utc` | `String?` | `startTimeUtc` | No |
| `end_time_utc` | `String?` | `endTimeUtc` | No |
| `exit_code` | `Int32?` | `exitCode` | No |
| `working_directory` | `ArtifactLocation?` | `workingDirectory` | No |

### Artifact

Describes a file relevant to the analysis.

```crystal
Sarif::Artifact.new(
  location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
  mime_type: "text/x-crystal",
  roles: [Sarif::ArtifactRole::AnalysisTarget],
  length: 2048_i64
)
```

### VersionControlDetails

Source control metadata.

```crystal
Sarif::VersionControlDetails.new(
  repository_uri: "https://github.com/example/repo",
  revision_id: "abc123",
  branch: "main"
)
```

### Conversion

Describes a conversion from another format.

```crystal
Sarif::Conversion.new(
  tool: Sarif::Tool.new(
    driver: Sarif::ToolComponent.new(name: "Converter")
  )
)
```

## Example

```crystal
run = Sarif::Run.new(
  tool: Sarif::Tool.new(
    driver: Sarif::ToolComponent.new(
      name: "SecurityScanner", version: "3.0"
    )
  ),
  results: [
    Sarif::Result.new(
      message: Sarif::Message.new(text: "SQL injection risk"),
      rule_id: "SEC001",
      level: Sarif::Level::Error
    ),
  ],
  invocations: [
    Sarif::Invocation.new(execution_successful: true),
  ],
  column_kind: Sarif::ColumnKind::Utf16CodeUnits,
  version_control_provenance: [
    Sarif::VersionControlDetails.new(
      repository_uri: "https://github.com/example/app",
      branch: "main"
    ),
  ]
)
```
