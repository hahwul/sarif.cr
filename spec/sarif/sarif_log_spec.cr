require "../spec_helper"

describe Sarif::SarifLog do
  it "creates a minimal SARIF log" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "TestTool"))
        ),
      ]
    )
    log.version.should eq("2.1.0")
    log.schema.should eq(Sarif::SARIF_SCHEMA)
    log.runs.size.should eq(1)
  end

  it "serializes to valid JSON with $schema" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))
        ),
      ]
    )
    json = log.to_json
    parsed = JSON.parse(json)
    parsed["version"].as_s.should eq("2.1.0")
    parsed["$schema"].as_s.should contain("sarif-schema-2.1.0.json")
    parsed["runs"].as_a.size.should eq(1)
  end

  it "round-trips through JSON" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(name: "Analyzer", version: "2.0",
              rules: [
                Sarif::ReportingDescriptor.new(id: "R001", name: "TestRule"),
              ]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "Found issue"),
              rule_id: "R001", rule_index: 0,
              level: Sarif::Level::Warning,
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    artifact_location: Sarif::ArtifactLocation.new(uri: "src/app.cr"),
                    region: Sarif::Region.new(start_line: 42, start_column: 10)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    json = log.to_json
    restored = Sarif::SarifLog.from_json(json)
    restored.version.should eq("2.1.0")
    restored.runs.size.should eq(1)
    restored.runs[0].tool.driver.name.should eq("Analyzer")
    restored.runs[0].tool.driver.rules.not_nil![0].id.should eq("R001")
    restored.runs[0].results.not_nil![0].message.text.should eq("Found issue")
    restored.runs[0].results.not_nil![0].locations.not_nil![0]
      .physical_location.not_nil!.region.not_nil!.start_line.should eq(42)
  end

  it "supports pretty JSON output" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))
        ),
      ]
    )
    pretty = log.to_pretty_json
    pretty.should contain("\"version\"")
    pretty.should contain("\n")
  end

  it "supports multiple runs" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool1"))),
        Sarif::Run.new(tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool2"))),
      ]
    )
    log.runs.size.should eq(2)
    json = log.to_json
    restored = Sarif::SarifLog.from_json(json)
    restored.runs[0].tool.driver.name.should eq("Tool1")
    restored.runs[1].tool.driver.name.should eq("Tool2")
  end
end
