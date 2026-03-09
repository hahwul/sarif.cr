+++
title = "Result"
description = "API reference for the Result class and related types."
weight = 3
+++

A `Result` represents a single finding from an analysis tool. It is the primary output object in SARIF.

## Constructor

```crystal
Sarif::Result.new(
  message : Sarif::Message,
  rule_id : String? = nil,
  rule_index : Int32? = nil,
  level : Sarif::Level? = nil,
  kind : Sarif::ResultKind? = nil,
  locations : Array(Sarif::Location)? = nil,
  # ... additional optional parameters
)
```

## Properties

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `message` | `Message` | `message` | Description of the result (required) |
| `rule_id` | `String?` | `ruleId` | Stable identifier for the rule |
| `rule_index` | `Int32?` | `ruleIndex` | Index into `tool.driver.rules` |
| `rule` | `ReportingDescriptorReference?` | `rule` | Reference to the rule |
| `kind` | `ResultKind?` | `kind` | Classification of the result |
| `level` | `Level?` | `level` | Severity level |
| `locations` | `Array(Location)?` | `locations` | Where the result was found |
| `analysis_target` | `ArtifactLocation?` | `analysisTarget` | The file being analyzed |
| `guid` | `String?` | `guid` | Unique identifier for this result |
| `correlation_guid` | `String?` | `correlationGuid` | Groups related results |
| `occurrence_count` | `Int32?` | `occurrenceCount` | Number of occurrences |
| `partial_fingerprints` | `Hash(String, String)?` | `partialFingerprints` | Partial identity data |
| `fingerprints` | `Hash(String, String)?` | `fingerprints` | Full identity data |
| `stacks` | `Array(Stack)?` | `stacks` | Call stacks |
| `code_flows` | `Array(CodeFlow)?` | `codeFlows` | Code flow paths |
| `graphs` | `Array(Graph)?` | `graphs` | Associated graphs |
| `graph_traversals` | `Array(GraphTraversal)?` | `graphTraversals` | Graph traversals |
| `related_locations` | `Array(Location)?` | `relatedLocations` | Related code locations |
| `suppressions` | `Array(Suppression)?` | `suppressions` | Suppression info |
| `baseline_state` | `BaselineState?` | `baselineState` | Baseline comparison |
| `rank` | `Float64?` | `rank` | Priority ranking (0.0 - 100.0) |
| `fixes` | `Array(Fix)?` | `fixes` | Proposed fixes |
| `taxa` | `Array(ReportingDescriptorReference)?` | `taxa` | Taxonomy references |
| `web_request` | `WebRequest?` | `webRequest` | Associated HTTP request |
| `web_response` | `WebResponse?` | `webResponse` | Associated HTTP response |
| `provenance` | `ResultProvenance?` | `provenance` | Detection history |
| `work_item_uris` | `Array(String)?` | `workItemUris` | Linked work items |
| `properties` | `PropertyBag?` | `properties` | Custom properties |

## Instance Methods

### `#effective_level`

Returns the level, defaulting to `Level::Warning` per the SARIF spec:

```crystal
result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))
result.effective_level  # => Sarif::Level::Warning
```

### `#effective_kind`

Returns the kind, defaulting to `ResultKind::Fail` per the SARIF spec:

```crystal
result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))
result.effective_kind   # => Sarif::ResultKind::Fail
```

## Related Types

### Suppression

Records that a result has been suppressed.

```crystal
Sarif::Suppression.new(
  kind: Sarif::SuppressionKind::InSource,
  status: Sarif::SuppressionStatus::Accepted,
  justification: "False positive - output is HTML-escaped"
)
```

### CodeFlow

Represents a path through code (e.g., taint flow):

```crystal
Sarif::CodeFlow.new(
  thread_flows: [
    Sarif::ThreadFlow.new(
      locations: [
        Sarif::ThreadFlowLocation.new(
          location: Sarif::Location.new(
            physical_location: Sarif::PhysicalLocation.new(
              artifact_location: Sarif::ArtifactLocation.new(uri: "src/app.cr"),
              region: Sarif::Region.new(start_line: 10)
            )
          ),
          importance: Sarif::Importance::Essential
        ),
      ]
    ),
  ]
)
```

### Fix

A proposed fix for the result:

```crystal
Sarif::Fix.new(
  description: Sarif::Message.new(text: "Remove unused variable"),
  artifact_changes: [
    Sarif::ArtifactChange.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "src/app.cr"),
      replacements: [
        Sarif::Replacement.new(
          deleted_region: Sarif::Region.new(
            start_line: 10, start_column: 1,
            end_line: 10, end_column: 20
          )
        ),
      ]
    ),
  ]
)
```

## Example

```crystal
result = Sarif::Result.new(
  message: Sarif::Message.new(text: "Possible SQL injection"),
  rule_id: "SEC001",
  rule_index: 0,
  level: Sarif::Level::Error,
  kind: Sarif::ResultKind::Fail,
  locations: [
    Sarif::Location.new(
      physical_location: Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "src/db.cr"),
        region: Sarif::Region.new(start_line: 42, start_column: 10)
      )
    ),
  ],
  fingerprints: {"primaryLocationLineHash" => "abc123"},
  baseline_state: Sarif::BaselineState::New
)
```
