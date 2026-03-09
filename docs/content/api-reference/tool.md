+++
title = "Tool"
description = "API reference for Tool, ToolComponent, and ReportingDescriptor."
weight = 4
+++

The `Tool` class describes the analysis tool that produced the results. It consists of a required `driver` component and optional `extensions`.

## Tool

```crystal
Sarif::Tool.new(
  driver : Sarif::ToolComponent,
  extensions : Array(Sarif::ToolComponent)? = nil,
  properties : Sarif::PropertyBag? = nil
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `driver` | `ToolComponent` | `driver` | The primary tool component (required) |
| `extensions` | `Array(ToolComponent)?` | `extensions` | Plugins or extensions |
| `properties` | `PropertyBag?` | `properties` | Custom properties |

## ToolComponent

Describes a tool component (driver or extension).

```crystal
Sarif::ToolComponent.new(
  name : String,
  version : String? = nil,
  semantic_version : String? = nil,
  guid : String? = nil,
  information_uri : String? = nil,
  rules : Array(Sarif::ReportingDescriptor)? = nil,
  # ... additional optional parameters
)
```

### Properties

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `name` | `String` | `name` | Tool name (required) |
| `version` | `String?` | `version` | Tool version |
| `semantic_version` | `String?` | `semanticVersion` | Semantic version string |
| `guid` | `String?` | `guid` | Unique identifier |
| `organization` | `String?` | `organization` | Organization name |
| `product` | `String?` | `product` | Product name |
| `full_name` | `String?` | `fullName` | Full display name |
| `short_description` | `MultiformatMessageString?` | `shortDescription` | Brief description |
| `full_description` | `MultiformatMessageString?` | `fullDescription` | Detailed description |
| `information_uri` | `String?` | `informationUri` | Documentation URL |
| `download_uri` | `String?` | `downloadUri` | Download URL |
| `rules` | `Array(ReportingDescriptor)?` | `rules` | Analysis rules |
| `notifications` | `Array(ReportingDescriptor)?` | `notifications` | Notification descriptors |
| `taxa` | `Array(ReportingDescriptor)?` | `taxa` | Taxonomy items |
| `language` | `String?` | `language` | Localization language |
| `contents` | `Array(ToolComponentContent)?` | `contents` | Content types |
| `global_message_strings` | `Hash(String, MultiformatMessageString)?` | `globalMessageStrings` | Shared message templates |
| `translation_metadata` | `TranslationMetadata?` | `translationMetadata` | Translation info |
| `properties` | `PropertyBag?` | `properties` | Custom properties |

## ReportingDescriptor

Describes a rule, notification, or taxonomy item.

```crystal
Sarif::ReportingDescriptor.new(
  id : String,
  name : String? = nil,
  short_description : Sarif::MultiformatMessageString? = nil,
  full_description : Sarif::MultiformatMessageString? = nil,
  help_uri : String? = nil,
  default_configuration : Sarif::ReportingConfiguration? = nil,
  # ... additional optional parameters
)
```

### Properties

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `id` | `String` | `id` | Stable rule identifier (required) |
| `name` | `String?` | `name` | Rule name |
| `guid` | `String?` | `guid` | Unique identifier |
| `short_description` | `MultiformatMessageString?` | `shortDescription` | Brief description |
| `full_description` | `MultiformatMessageString?` | `fullDescription` | Detailed description |
| `message_strings` | `Hash(String, MultiformatMessageString)?` | `messageStrings` | Message templates |
| `default_configuration` | `ReportingConfiguration?` | `defaultConfiguration` | Default settings |
| `help_uri` | `String?` | `helpUri` | Help documentation URL |
| `help` | `MultiformatMessageString?` | `help` | Full help text |
| `relationships` | `Array(ReportingDescriptorRelationship)?` | `relationships` | Related rules/taxa |
| `deprecated_ids` | `Array(String)?` | `deprecatedIds` | Former identifiers |
| `properties` | `PropertyBag?` | `properties` | Custom properties |

## ReportingConfiguration

Default settings for a rule.

```crystal
Sarif::ReportingConfiguration.new(
  enabled: true,
  level: Sarif::Level::Warning,
  rank: 50.0
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `enabled` | `Bool?` | `enabled` | Whether the rule is enabled |
| `level` | `Level?` | `level` | Default severity level |
| `rank` | `Float64?` | `rank` | Default priority ranking |
| `parameters` | `PropertyBag?` | `parameters` | Rule parameters |

## MultiformatMessageString

A message with optional markdown formatting.

```crystal
Sarif::MultiformatMessageString.new(
  text: "SQL Injection vulnerability",
  markdown: "**SQL Injection** vulnerability"
)
```

## Example

```crystal
tool = Sarif::Tool.new(
  driver: Sarif::ToolComponent.new(
    name: "SecurityScanner",
    version: "3.0",
    information_uri: "https://example.com/scanner",
    rules: [
      Sarif::ReportingDescriptor.new(
        id: "SEC001",
        name: "SqlInjection",
        short_description: Sarif::MultiformatMessageString.new(
          text: "SQL Injection vulnerability"
        ),
        default_configuration: Sarif::ReportingConfiguration.new(
          level: Sarif::Level::Error
        ),
        help_uri: "https://example.com/rules/SEC001"
      ),
    ]
  ),
  extensions: [
    Sarif::ToolComponent.new(
      name: "XSSPlugin",
      version: "1.0"
    ),
  ]
)
```
