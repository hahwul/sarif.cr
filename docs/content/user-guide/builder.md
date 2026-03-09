+++
title = "Builder"
description = "Use the fluent builder API to construct SARIF documents with minimal boilerplate."
weight = 3
+++

The `Sarif::Builder` provides a fluent API for constructing SARIF documents. It handles object wiring (tool, rules, results, ruleIndex linking) so you can focus on your data.

## Basic Usage

```crystal
log = Sarif::Builder.build do |b|
  b.run("MyTool", "1.0.0") do |r|
    r.result("Issue found", level: Sarif::Level::Warning)
  end
end
```

## Adding Rules

Define rules before results. The builder auto-links `ruleIndex` when a result references a `rule_id`:

```crystal
log = Sarif::Builder.build do |b|
  b.run("Linter") do |r|
    r.rule("R001", name: "NoUnused",
           short_description: "No unused variables",
           level: Sarif::Level::Warning)
    r.rule("R002", name: "NoShadow",
           short_description: "No shadowed variables",
           level: Sarif::Level::Error)

    r.result("Variable 'x' is unused",
             rule_id: "R001", level: Sarif::Level::Warning,
             uri: "src/app.cr", start_line: 15)
    r.result("Variable 'i' shadows outer 'i'",
             rule_id: "R002", level: Sarif::Level::Error,
             uri: "src/loop.cr", start_line: 22, start_column: 5)
  end
end
```

The resulting JSON will have `ruleIndex: 0` for the first result and `ruleIndex: 1` for the second.

## Result Builder Block

For more control, use the block form:

```crystal
log = Sarif::Builder.build do |b|
  b.run("Tool") do |r|
    r.result do |rb|
      rb.message("Complex issue", markdown: "**Complex** issue")
      rb.rule_id("R1")
      rb.level(Sarif::Level::Error)
      rb.location(uri: "file.cr", start_line: 5, end_line: 10)
      rb.related_location(uri: "other.cr", start_line: 20,
                          message_text: "Related code", id: 1)
      rb.fingerprint("primary", "hash123")
    end
  end
end
```

## Adding Artifacts

Register analyzed files:

```crystal
log = Sarif::Builder.build do |b|
  b.run("Scanner") do |r|
    r.artifact("src/main.cr", mime_type: "text/x-crystal")
    r.artifact("src/utils.cr", mime_type: "text/x-crystal")
    r.result("Issue in main", uri: "src/main.cr", start_line: 1)
  end
end
```

## Adding Invocations

Record how the tool was invoked:

```crystal
log = Sarif::Builder.build do |b|
  b.run("Scanner") do |r|
    r.invocation(true, "scanner --check src/")
    r.result("Found issue", level: Sarif::Level::Warning)
  end
end
```

## Multiple Runs

A single SARIF log can contain results from multiple tools:

```crystal
log = Sarif::Builder.build do |b|
  b.run("Linter", "1.0") do |r|
    r.result("Style issue", level: Sarif::Level::Note)
  end
  b.run("SecurityScanner", "2.0") do |r|
    r.result("Vulnerability found", level: Sarif::Level::Error)
  end
end
```

## Complete Example

```crystal
log = Sarif::Builder.build do |b|
  b.run("CrystalLint", "2.0.0") do |r|
    r.rule("CL001", name: "UnusedVar",
           short_description: "Unused variable detected",
           help_uri: "https://example.com/rules/CL001")
    r.rule("CL002", name: "ShadowVar",
           short_description: "Variable shadows outer scope")

    r.artifact("src/app.cr", mime_type: "text/x-crystal")
    r.artifact("src/loop.cr", mime_type: "text/x-crystal")

    r.invocation(true, "crystal-lint src/")

    r.result("Variable 'x' is never used",
             rule_id: "CL001", level: Sarif::Level::Warning,
             uri: "src/app.cr", start_line: 15)
    r.result("Variable 'i' shadows outer 'i'",
             rule_id: "CL002", level: Sarif::Level::Note,
             uri: "src/loop.cr", start_line: 22, start_column: 5)
  end
end

puts log.to_pretty_json
```
