+++
title = "Getting Started"
description = "Install sarif.cr and create your first SARIF document."
weight = 1
+++

This guide walks you through installing sarif.cr and creating your first SARIF document.

## Prerequisites

- [Crystal](https://crystal-lang.org/) >= 1.19.1

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  sarif:
    github: hahwul/sarif
```

Then install:

```bash
shards install
```

## Your First SARIF Document

Create a minimal SARIF log with a single result:

```crystal
require "sarif"

log = Sarif::SarifLog.new(
  runs: [
    Sarif::Run.new(
      tool: Sarif::Tool.new(
        driver: Sarif::ToolComponent.new(name: "MyTool", version: "1.0")
      ),
      results: [
        Sarif::Result.new(
          message: Sarif::Message.new(text: "Unused variable found"),
          rule_id: "R001",
          level: Sarif::Level::Warning
        ),
      ]
    ),
  ]
)

puts log.to_pretty_json
```

This produces a valid SARIF 2.1.0 JSON document with the correct `$schema` and `version` fields.

## Using the Builder

For a more ergonomic approach, use the fluent builder API:

```crystal
require "sarif"

log = Sarif::Builder.build do |b|
  b.run("MyTool", "1.0") do |r|
    r.result("Unused variable found",
             rule_id: "R001",
             level: Sarif::Level::Warning,
             uri: "src/main.cr",
             start_line: 10)
  end
end

puts log.to_pretty_json
```

## What is SARIF?

SARIF (Static Analysis Results Interchange Format) is an OASIS standard that defines a JSON format for the output of static analysis tools. It provides a common schema so that different tools can produce results in a uniform way.

A SARIF document has this structure:

| Component | Required | Description |
|-----------|----------|-------------|
| `version` | Yes | SARIF version (always `"2.1.0"`) |
| `$schema` | No | JSON schema URI |
| `runs` | Yes | Array of analysis runs |

Each **Run** contains:

| Component | Required | Description |
|-----------|----------|-------------|
| `tool` | Yes | The tool that produced the results |
| `results` | No | Array of analysis results (findings) |
| `artifacts` | No | Files that were analyzed |
| `invocations` | No | How the tool was invoked |

Each **Result** contains:

| Component | Required | Description |
|-----------|----------|-------------|
| `message` | Yes | Human-readable description |
| `ruleId` | No | Identifier of the rule that was violated |
| `level` | No | Severity: `error`, `warning`, `note`, `none` |
| `locations` | No | Where the issue was found |

## Next Steps

- **[Basic Usage](/user-guide/basic-usage/)** -- Work with SARIF objects directly
- **[Builder](/user-guide/builder/)** -- Use the fluent builder API
- **[Parsing & Validation](/user-guide/parsing-and-validation/)** -- Read and validate SARIF files
