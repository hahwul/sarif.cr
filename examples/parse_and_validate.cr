require "../src/sarif"

# =============================================================================
# Parse SARIF JSON and validate the resulting log
# =============================================================================
# `Sarif.parse(string|io)` returns a SarifLog. `Sarif.parse!` additionally runs
# the Validator and raises on errors. `Sarif.from_file` / `from_file!` are the
# file-path equivalents. `Validator#validate` returns a structured result you
# can inspect when you want soft validation.

sarif_json = <<-JSON
  {
    "version": "2.1.0",
    "$schema": "https://docs.oasis-open.org/sarif/sarif/v2.1.0/cos02/schemas/sarif-schema-2.1.0.json",
    "runs": [
      {
        "tool": {
          "driver": {
            "name": "DemoScanner",
            "version": "0.1.0",
            "rules": [
              { "id": "DEMO001", "name": "HardcodedSecret" }
            ]
          }
        },
        "results": [
          {
            "ruleId": "DEMO001",
            "ruleIndex": 0,
            "level": "error",
            "message": { "text": "Hardcoded AWS access key detected" },
            "locations": [
              {
                "physicalLocation": {
                  "artifactLocation": { "uri": "config/app.yml" },
                  "region": { "startLine": 12 }
                }
              }
            ]
          }
        ]
      }
    ]
  }
  JSON

puts "--- parse ---"
log = Sarif.parse(sarif_json)
puts "  version : #{log.version}"
puts "  results : #{log.runs.first.results.try(&.size) || 0}"

puts "\n--- validate ---"
validator = Sarif::Validator.new
result = validator.validate(log)
puts "  valid?  : #{result.valid?}"
puts "  errors  : #{result.errors.size}"
result.errors.each { |e| puts "    - #{e.message}" }

puts "\n--- invalid input: missing version ---"
bad = sarif_json.sub("\"version\": \"2.1.0\",", "")
begin
  Sarif.parse!(bad)
  puts "  parse! did not raise (unexpected)"
rescue ex
  puts "  parse! raised #{ex.class}: #{ex.message}"
end
