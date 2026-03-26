+++
title = "PropertyBag"
description = "API reference for the PropertyBag class with typed accessors."
weight = 7
+++

A `PropertyBag` stores arbitrary key-value metadata on any SARIF object. It supports both dynamic access and type-safe accessors.

## Constructor

```crystal
Sarif::PropertyBag.new(tags : Array(String)? = nil)
```

## Dynamic Access

```crystal
bag = Sarif::PropertyBag.new
bag["score"] = JSON::Any.new(95.0)
bag["score"]   # => JSON::Any(95.0)
bag["score"]?  # => JSON::Any(95.0) or nil
```

## Typed Accessors

Safe retrieval methods that return `nil` on type mismatch, with optional defaults:

```crystal
bag.get_string("name")              # => String?
bag.get_string("name", "unknown")   # => String (with default)

bag.get_int("count")                # => Int64?
bag.get_int("count", 0_i64)         # => Int64 (with default)

bag.get_float("score")              # => Float64?
bag.get_float("score", 0.0)         # => Float64 (with default)

bag.get_bool("enabled")             # => Bool?
bag.get_bool("enabled", false)      # => Bool (with default)
```

## Utility Methods

```crystal
bag.has_key?("score")  # => true
bag.size               # => 1 (custom properties, excluding tags)
bag.keys               # => ["score"]
```

## Tags

```crystal
bag = Sarif::PropertyBag.new(tags: ["security", "critical"])
bag.tags  # => ["security", "critical"]
```

## Merging

Merge another PropertyBag into the current one. Existing keys are overwritten; tags are deduplicated:

```crystal
a = Sarif::PropertyBag.new(tags: ["security"])
a["key"] = JSON::Any.new("value1")

b = Sarif::PropertyBag.new(tags: ["security", "new"])
b["key"] = JSON::Any.new("value2")

a.merge!(b)
a.get_string("key")  # => "value2" (overwritten)
a.tags                # => ["security", "new"] (deduplicated)
```
