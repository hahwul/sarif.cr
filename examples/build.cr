require "../src/sarif"

# =============================================================================
# Build a SARIF 2.1.0 log with the Builder DSL
# =============================================================================
# Builder lets you declare a run (a single analysis tool invocation), then add
# rules (rule definitions) and results (findings). Results that name a rule_id
# are automatically linked back to the matching rule definition.

log = Sarif::Builder.build do |b|
  b.run("ExampleLinter", "1.0.0") do |r|
    r.rule(
      "LINT001",
      name: "UnusedVariable",
      short_description: "Variable is declared but never used",
    )
    r.rule(
      "LINT002",
      name: "ShadowedVariable",
      short_description: "Outer variable shadowed by inner declaration",
    )

    r.result(
      "Variable 'x' is never used",
      rule_id: "LINT001",
      level: Sarif::Level::Warning,
      uri: "src/main.cr",
      start_line: 10,
    )
    r.result(
      "Variable 'i' shadows the outer 'i' at line 8",
      rule_id: "LINT002",
      level: Sarif::Level::Warning,
      uri: "src/main.cr",
      start_line: 14,
    )
  end
end

puts "--- Built SARIF log ---"
puts "Schema     : #{log.schema}"
puts "Version    : #{log.version}"
puts "Runs       : #{log.runs.size}"
puts "Tool       : #{log.runs.first.tool.driver.name} v#{log.runs.first.tool.driver.version}"
puts "Rules      : #{log.runs.first.tool.driver.rules.try(&.size) || 0}"
puts "Results    : #{log.runs.first.results.try(&.size) || 0}"

puts "\n--- Pretty JSON (head) ---"
puts log.to_pretty_json.lines.first(20).join("\n")
puts "..."
