+++
title = "Location"
description = "API reference for Location, PhysicalLocation, Region, and related types."
weight = 5
+++

Location types describe where in the source code a result was found.

## Location

The top-level location object, combining physical and logical locations.

```crystal
Sarif::Location.new(
  id : Int32? = nil,
  physical_location : Sarif::PhysicalLocation? = nil,
  logical_locations : Array(Sarif::LogicalLocation)? = nil,
  message : Sarif::Message? = nil,
  annotations : Array(Sarif::Region)? = nil,
  relationships : Array(Sarif::LocationRelationship)? = nil,
  properties : Sarif::PropertyBag? = nil
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `id` | `Int32?` | `id` | Location identifier within the result |
| `physical_location` | `PhysicalLocation?` | `physicalLocation` | File and region |
| `logical_locations` | `Array(LogicalLocation)?` | `logicalLocations` | Namespace/class/function |
| `message` | `Message?` | `message` | Description of this location |
| `annotations` | `Array(Region)?` | `annotations` | Annotated regions |
| `relationships` | `Array(LocationRelationship)?` | `relationships` | Relations to other locations |

## PhysicalLocation

A location within a file, identified by URI and region.

```crystal
Sarif::PhysicalLocation.new(
  artifact_location : Sarif::ArtifactLocation? = nil,
  region : Sarif::Region? = nil,
  context_region : Sarif::Region? = nil,
  address : Sarif::Address? = nil,
  properties : Sarif::PropertyBag? = nil
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `artifact_location` | `ArtifactLocation?` | `artifactLocation` | File URI |
| `region` | `Region?` | `region` | Precise region of the finding |
| `context_region` | `Region?` | `contextRegion` | Surrounding context |
| `address` | `Address?` | `address` | Memory address |

## ArtifactLocation

Identifies a file by URI.

```crystal
Sarif::ArtifactLocation.new(
  uri : String? = nil,
  uri_base_id : String? = nil,
  index : Int32? = nil,
  description : Sarif::Message? = nil
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `uri` | `String?` | `uri` | File path or URI |
| `uri_base_id` | `String?` | `uriBaseId` | Base URI identifier (e.g., `%SRCROOT%`) |
| `index` | `Int32?` | `index` | Index into `run.artifacts` |
| `description` | `Message?` | `description` | Description of the artifact |

## Region

A contiguous area within a file.

```crystal
Sarif::Region.new(
  start_line : Int32? = nil,
  start_column : Int32? = nil,
  end_line : Int32? = nil,
  end_column : Int32? = nil,
  byte_offset : Int32? = nil,
  byte_length : Int32? = nil,
  char_offset : Int32? = nil,
  char_length : Int32? = nil,
  snippet : Sarif::ArtifactContent? = nil,
  message : Sarif::Message? = nil,
  source_language : String? = nil
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `start_line` | `Int32?` | `startLine` | 1-based start line |
| `start_column` | `Int32?` | `startColumn` | 1-based start column |
| `end_line` | `Int32?` | `endLine` | 1-based end line |
| `end_column` | `Int32?` | `endColumn` | 1-based exclusive end column |
| `byte_offset` | `Int32?` | `byteOffset` | Byte offset from file start |
| `byte_length` | `Int32?` | `byteLength` | Region length in bytes |
| `char_offset` | `Int32?` | `charOffset` | Character offset |
| `char_length` | `Int32?` | `charLength` | Region length in characters |
| `snippet` | `ArtifactContent?` | `snippet` | Source code snippet |
| `source_language` | `String?` | `sourceLanguage` | Language of the region |

## LogicalLocation

A location described by its logical position (namespace, class, function).

```crystal
Sarif::LogicalLocation.new(
  name : String? = nil,
  fully_qualified_name : String? = nil,
  kind : String? = nil,
  parent_index : Int32? = nil
)
```

| Property | Type | JSON Key | Description |
|----------|------|----------|-------------|
| `name` | `String?` | `name` | Short name (e.g., `"process"`) |
| `fully_qualified_name` | `String?` | `fullyQualifiedName` | Full name (e.g., `"MyModule::MyClass#process"`) |
| `decorated_name` | `String?` | `decoratedName` | Compiler-decorated name |
| `kind` | `String?` | `kind` | Kind: `"function"`, `"type"`, `"namespace"`, etc. |
| `parent_index` | `Int32?` | `parentIndex` | Index of parent logical location |

## LocationRelationship

Describes a relationship between two locations.

```crystal
Sarif::LocationRelationship.new(
  target: 1,
  kinds: ["isResultOf"]
)
```

## Example

```crystal
location = Sarif::Location.new(
  id: 0,
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
  ),
  logical_locations: [
    Sarif::LogicalLocation.new(
      name: "handle_login",
      fully_qualified_name: "UserController#handle_login",
      kind: "function"
    ),
  ],
  message: Sarif::Message.new(text: "User input flows into SQL query")
)
```
