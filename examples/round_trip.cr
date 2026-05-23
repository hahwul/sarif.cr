require "../src/sarif"

# =============================================================================
# Round-trip: build -> JSON -> parse -> validate
# =============================================================================
# A nice way to catch builder regressions: anything you produce should also be
# parseable by your own parser, and round-trip without losing structure.

original = Sarif::Builder.build do |b|
  b.run("RoundTripDemo", "0.1.0") do |r|
    r.rule("R001", name: "Demo", short_description: "Demo rule")
    r.result(
      "Demo finding",
      rule_id: "R001",
      level: Sarif::Level::Note,
      uri: "src/example.cr",
      start_line: 1,
    )
  end
end

json = original.to_json
parsed = Sarif.parse(json)
validation = Sarif::Validator.new.validate(parsed)

puts "--- Round-trip ---"
puts "  serialize -> parse OK"
puts "  same version    : #{original.version == parsed.version}"
puts "  same run count  : #{original.runs.size == parsed.runs.size}"
puts "  same rule id    : #{original.runs.first.tool.driver.rules.try(&.first.id) == \
                              parsed.runs.first.tool.driver.rules.try(&.first.id)}"
puts "  same finding txt: #{original.runs.first.results.try(&.first.message.text) == \
                              parsed.runs.first.results.try(&.first.message.text)}"
puts "  validator valid?: #{validation.valid?}"
