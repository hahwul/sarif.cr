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

  it "returns all results across runs" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool1")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1", level: Sarif::Level::Error),
            Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R2", level: Sarif::Level::Warning),
          ]
        ),
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool2")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R1", level: Sarif::Level::Error),
          ]
        ),
      ]
    )
    log.all_results.size.should eq(3)
  end

  it "filters results by level" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "A"), level: Sarif::Level::Error),
            Sarif::Result.new(message: Sarif::Message.new(text: "B"), level: Sarif::Level::Warning),
            Sarif::Result.new(message: Sarif::Message.new(text: "C"), level: Sarif::Level::Error),
          ]
        ),
      ]
    )
    log.results_by_level(Sarif::Level::Error).size.should eq(2)
    log.results_by_level(Sarif::Level::Warning).size.should eq(1)
  end

  it "filters results by rule_id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1"),
            Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R2"),
            Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R1"),
          ]
        ),
      ]
    )
    log.results_by_rule_id("R1").size.should eq(2)
    log.results_by_rule_id("R2").size.should eq(1)
    log.results_by_rule_id("R999").size.should eq(0)
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

  describe "#find_results" do
    it "filters across runs with multiple criteria" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool1")),
            results: [
              Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1", level: Sarif::Level::Error),
              Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R2", level: Sarif::Level::Warning),
            ]
          ),
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool2")),
            results: [
              Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R1", level: Sarif::Level::Error),
            ]
          ),
        ]
      )
      log.find_results(rule_id: "R1", level: Sarif::Level::Error).size.should eq(2)
      log.find_results(rule_id: "R2").size.should eq(1)
      log.find_results(level: Sarif::Level::Warning).size.should eq(1)
    end
  end

  describe "#find_locations_in_file" do
    it "finds locations by file URI" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [
              Sarif::Result.new(
                message: Sarif::Message.new(text: "A"),
                locations: [
                  Sarif::Location.new(
                    physical_location: Sarif::PhysicalLocation.new(
                      artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
                      region: Sarif::Region.new(start_line: 10)
                    )
                  ),
                ]
              ),
              Sarif::Result.new(
                message: Sarif::Message.new(text: "B"),
                locations: [
                  Sarif::Location.new(
                    physical_location: Sarif::PhysicalLocation.new(
                      artifact_location: Sarif::ArtifactLocation.new(uri: "src/other.cr"),
                      region: Sarif::Region.new(start_line: 5)
                    )
                  ),
                ]
              ),
              Sarif::Result.new(
                message: Sarif::Message.new(text: "C"),
                locations: [
                  Sarif::Location.new(
                    physical_location: Sarif::PhysicalLocation.new(
                      artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
                      region: Sarif::Region.new(start_line: 20)
                    )
                  ),
                ]
              ),
            ]
          ),
        ]
      )
      locs = log.find_locations_in_file("src/main.cr")
      locs.size.should eq(2)
      locs[0].physical_location.not_nil!.region.not_nil!.start_line.should eq(10)
      locs[1].physical_location.not_nil!.region.not_nil!.start_line.should eq(20)
    end

    it "returns empty for non-matching file" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [
              Sarif::Result.new(message: Sarif::Message.new(text: "A"),
                locations: [
                  Sarif::Location.new(
                    physical_location: Sarif::PhysicalLocation.new(
                      artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr")
                    )
                  ),
                ]
              ),
            ]
          ),
        ]
      )
      log.find_locations_in_file("src/nonexistent.cr").should be_empty
    end
  end

  describe "#result_counts_by_level" do
    it "counts results by level across runs" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [
              Sarif::Result.new(message: Sarif::Message.new(text: "A"), level: Sarif::Level::Error),
              Sarif::Result.new(message: Sarif::Message.new(text: "B"), level: Sarif::Level::Warning),
              Sarif::Result.new(message: Sarif::Message.new(text: "C"), level: Sarif::Level::Error),
            ]
          ),
        ]
      )
      counts = log.result_counts_by_level
      counts[Sarif::Level::Error].should eq(2)
      counts[Sarif::Level::Warning].should eq(1)
    end
  end

  describe "#result_counts_by_rule_id" do
    it "counts results by rule_id across runs" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [
              Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1"),
              Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R2"),
              Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R1"),
            ]
          ),
        ]
      )
      counts = log.result_counts_by_rule_id
      counts["R1"].should eq(2)
      counts["R2"].should eq(1)
    end
  end

  describe "#valid?" do
    it "returns true for valid log" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [Sarif::Result.new(message: Sarif::Message.new(text: "issue"))]
          ),
        ]
      )
      log.valid?.should be_true
    end

    it "returns false for invalid version" do
      log = Sarif::SarifLog.new(
        version: "1.0.0",
        runs: [
          Sarif::Run.new(tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))),
        ]
      )
      log.valid?.should be_false
    end

    it "returns false when a run is invalid" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: ""))),
        ]
      )
      log.valid?.should be_false
    end

    it "returns false when a result in a run is invalid" do
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [Sarif::Result.new(message: Sarif::Message.new)]
          ),
        ]
      )
      log.valid?.should be_false
    end
  end
end
