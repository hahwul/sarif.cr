+++
title = "Enums"
description = "API reference for all SARIF enum types and the sarif_enum macro."
weight = 6
+++

sarif.cr provides type-safe enums for all SARIF enumerated values. Enums serialize to lowerCamelCase JSON strings using the `sarif_enum` macro.

## Level

Severity level for results and notifications.

| Value | JSON | Description |
|-------|------|-------------|
| `Level::None` | `"none"` | No severity |
| `Level::Note` | `"note"` | Informational |
| `Level::Warning` | `"warning"` | Warning (default for results) |
| `Level::Error` | `"error"` | Error |

```crystal
Sarif::Level::Warning.to_json  # => "\"warning\""
Sarif::Level.from_json("\"error\"")  # => Sarif::Level::Error
```

## ResultKind

Classification of a result.

| Value | JSON | Description |
|-------|------|-------------|
| `ResultKind::NotApplicable` | `"notApplicable"` | Rule does not apply |
| `ResultKind::Pass` | `"pass"` | Analysis passed |
| `ResultKind::Fail` | `"fail"` | Analysis failed (default) |
| `ResultKind::Review` | `"review"` | Needs human review |
| `ResultKind::Open` | `"open"` | Open question |
| `ResultKind::Informational` | `"informational"` | Informational only |

## BaselineState

State of a result relative to a baseline.

| Value | JSON | Description |
|-------|------|-------------|
| `BaselineState::New` | `"new"` | First appearance |
| `BaselineState::Unchanged` | `"unchanged"` | Same as baseline |
| `BaselineState::Updated` | `"updated"` | Changed since baseline |
| `BaselineState::Absent` | `"absent"` | No longer present |

## SuppressionKind

How a result was suppressed.

| Value | JSON | Description |
|-------|------|-------------|
| `SuppressionKind::InSource` | `"inSource"` | Suppressed via source annotation |
| `SuppressionKind::External` | `"external"` | Suppressed via external config |

## SuppressionStatus

Status of a suppression.

| Value | JSON | Description |
|-------|------|-------------|
| `SuppressionStatus::Accepted` | `"accepted"` | Suppression accepted |
| `SuppressionStatus::UnderReview` | `"underReview"` | Under review |
| `SuppressionStatus::Rejected` | `"rejected"` | Suppression rejected |

## Importance

Importance of a thread flow location.

| Value | JSON | Description |
|-------|------|-------------|
| `Importance::Important` | `"important"` | Important step |
| `Importance::Essential` | `"essential"` | Essential step |
| `Importance::Unimportant` | `"unimportant"` | Minor step |

## ArtifactRole

Role of an artifact in the analysis.

| Value | JSON |
|-------|------|
| `ArtifactRole::AnalysisTarget` | `"analysisTarget"` |
| `ArtifactRole::Attachment` | `"attachment"` |
| `ArtifactRole::ResponseFile` | `"responseFile"` |
| `ArtifactRole::ResultFile` | `"resultFile"` |
| `ArtifactRole::StandardStream` | `"standardStream"` |
| `ArtifactRole::TracedFile` | `"tracedFile"` |
| `ArtifactRole::Unmodified` | `"unmodified"` |
| `ArtifactRole::Modified` | `"modified"` |
| `ArtifactRole::Added` | `"added"` |
| `ArtifactRole::Deleted` | `"deleted"` |
| `ArtifactRole::Renamed` | `"renamed"` |
| `ArtifactRole::Uncontrolled` | `"uncontrolled"` |
| `ArtifactRole::Driver` | `"driver"` |
| `ArtifactRole::Extension` | `"extension"` |
| `ArtifactRole::Translation` | `"translation"` |
| `ArtifactRole::Taxonomy` | `"taxonomy"` |
| `ArtifactRole::Policy` | `"policy"` |
| `ArtifactRole::ReferencedOnCommandLine` | `"referencedOnCommandLine"` |
| `ArtifactRole::MemoryContents` | `"memoryContents"` |
| `ArtifactRole::Directory` | `"directory"` |
| `ArtifactRole::UserSpecifiedConfiguration` | `"userSpecifiedConfiguration"` |
| `ArtifactRole::ToolSpecifiedConfiguration` | `"toolSpecifiedConfiguration"` |
| `ArtifactRole::DebugOutputFile` | `"debugOutputFile"` |

## ColumnKind

How column numbers are counted.

| Value | JSON | Description |
|-------|------|-------------|
| `ColumnKind::Utf16CodeUnits` | `"utf16CodeUnits"` | UTF-16 code units |
| `ColumnKind::UnicodeCodePoints` | `"unicodeCodePoints"` | Unicode code points |

## ToolComponentContent

Type of content in a tool component.

| Value | JSON |
|-------|------|
| `ToolComponentContent::LocalizedData` | `"localizedData"` |
| `ToolComponentContent::NonLocalizedData` | `"nonLocalizedData"` |

## The `sarif_enum` Macro

All enums are defined using the `sarif_enum` macro, which auto-generates `to_json`, `from_json`, `to_s_sarif`, and `parse_sarif` methods:

```crystal
Sarif.sarif_enum(Level, {
  None    => "none",
  Note    => "note",
  Warning => "warning",
  Error   => "error",
})
```

This generates a Crystal `enum` with proper JSON serialization to/from the SARIF lowerCamelCase string values.
