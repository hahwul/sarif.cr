+++
title = "sarif.cr"
description = "Crystal implementation of the SARIF 2.1.0 specification"
+++

A Crystal library for working with [SARIF](https://sarifweb.azurewebsites.net/) (Static Analysis Results Interchange Format), the OASIS standard for representing static analysis tool output in a structured JSON format.

> Implements the full SARIF 2.1.0 specification with 50+ object types, fluent builder API, parsing, and validation.

## Overview

sarif.cr provides a complete, type-safe Crystal implementation of the SARIF 2.1.0 schema. It enables Crystal applications to generate, parse, and validate SARIF documents -- the standard interchange format used by tools like ESLint, Semgrep, CodeQL, and many others.

## Quick Links

- **[Getting Started](/user-guide/getting-started/)** -- Installation and your first SARIF document
- **[Basic Usage](/user-guide/basic-usage/)** -- Creating and manipulating SARIF objects
- **[Builder](/user-guide/builder/)** -- Fluent API for constructing SARIF documents
- **[API Reference](/api-reference/sarif-log/)** -- Complete API documentation

## Features

- **Full SARIF 2.1.0 Spec** -- All 50+ object types from the specification
- **Type-Safe** -- Crystal's type system ensures correctness at compile time
- **JSON Serialization** -- Automatic camelCase mapping with `JSON::Serializable`
- **Fluent Builder** -- Ergonomic API for constructing SARIF documents
- **Parse & Validate** -- Read existing SARIF files with schema validation
- **PropertyBag Support** -- Arbitrary custom properties via `JSON::Serializable::Unmapped`

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  sarif:
    github: hahwul/sarif
```

Then run:

```bash
shards install
```

## Quick Example

```crystal
require "sarif"

log = Sarif::Builder.build do |b|
  b.run("MyLinter", "1.0.0") do |r|
    r.rule("LINT001", name: "UnusedVar",
           short_description: "Unused variable detected")
    r.result("Variable 'x' is never used",
             rule_id: "LINT001",
             level: Sarif::Level::Warning,
             uri: "src/main.cr",
             start_line: 10)
  end
end

puts log.to_pretty_json
```
