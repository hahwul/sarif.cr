require "../spec_helper"

describe Sarif::Run do
  it "creates with tool" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "TestTool"))
    )
    run.tool.driver.name.should eq("TestTool")
    run.results.should be_nil
  end

  it "serializes with results" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Linter", version: "1.0")),
      results: [
        Sarif::Result.new(message: Sarif::Message.new(text: "Issue found"), rule_id: "R1"),
      ]
    )
    json = run.to_json
    parsed = JSON.parse(json)
    parsed["tool"]["driver"]["name"].as_s.should eq("Linter")
    parsed["results"][0]["message"]["text"].as_s.should eq("Issue found")
    parsed["results"][0]["ruleId"].as_s.should eq("R1")
  end

  it "supports invocations" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
      invocations: [
        Sarif::Invocation.new(execution_successful: true, command_line: "tool --check ."),
      ]
    )
    json = run.to_json
    parsed = JSON.parse(json)
    parsed["invocations"][0]["executionSuccessful"].as_bool.should be_true
    parsed["invocations"][0]["commandLine"].as_s.should eq("tool --check .")
  end

  it "supports artifacts" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
      artifacts: [
        Sarif::Artifact.new(
          location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
          mime_type: "text/x-crystal",
          roles: [Sarif::ArtifactRole::AnalysisTarget]
        ),
      ]
    )
    json = run.to_json
    parsed = JSON.parse(json)
    parsed["artifacts"][0]["location"]["uri"].as_s.should eq("src/main.cr")
    parsed["artifacts"][0]["mimeType"].as_s.should eq("text/x-crystal")
    parsed["artifacts"][0]["roles"][0].as_s.should eq("analysisTarget")
  end

  it "supports columnKind" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
      column_kind: Sarif::ColumnKind::Utf16CodeUnits
    )
    json = run.to_json
    parsed = JSON.parse(json)
    parsed["columnKind"].as_s.should eq("utf16CodeUnits")
  end

  it "supports versionControlProvenance" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
      version_control_provenance: [
        Sarif::VersionControlDetails.new(
          repository_uri: "https://github.com/example/repo",
          revision_id: "abc123",
          branch: "main"
        ),
      ]
    )
    json = run.to_json
    parsed = JSON.parse(json)
    parsed["versionControlProvenance"][0]["repositoryUri"].as_s.should eq("https://github.com/example/repo")
    parsed["versionControlProvenance"][0]["revisionId"].as_s.should eq("abc123")
    parsed["versionControlProvenance"][0]["branch"].as_s.should eq("main")
  end

  it "returns empty results from helpers when results is nil" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))
    )
    run.results_by_rule_id("R1").should be_empty
    run.results_by_level(Sarif::Level::Error).should be_empty
  end

  it "finds results by rule_id" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(
        driver: Sarif::ToolComponent.new(name: "Tool",
          rules: [
            Sarif::ReportingDescriptor.new(id: "R1"),
            Sarif::ReportingDescriptor.new(id: "R2"),
          ]
        )
      ),
      results: [
        Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1"),
        Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R2"),
        Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R1"),
      ]
    )
    run.results_by_rule_id("R1").size.should eq(2)
    run.results_by_rule_id("R2").size.should eq(1)
  end

  it "finds results by level" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
      results: [
        Sarif::Result.new(message: Sarif::Message.new(text: "A"), level: Sarif::Level::Error),
        Sarif::Result.new(message: Sarif::Message.new(text: "B"), level: Sarif::Level::Warning),
      ]
    )
    run.results_by_level(Sarif::Level::Error).size.should eq(1)
    run.results_by_level(Sarif::Level::Warning).size.should eq(1)
  end

  it "finds rule by id" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(
        driver: Sarif::ToolComponent.new(name: "Tool",
          rules: [
            Sarif::ReportingDescriptor.new(id: "R1", name: "Rule1"),
            Sarif::ReportingDescriptor.new(id: "R2", name: "Rule2"),
          ]
        )
      )
    )
    run.rule_by_id("R1").not_nil!.name.should eq("Rule1")
    run.rule_by_id("R2").not_nil!.name.should eq("Rule2")
    run.rule_by_id("R999").should be_nil
  end

  it "round-trips through JSON" do
    run = Sarif::Run.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "MyTool", version: "1.0")),
      results: [
        Sarif::Result.new(message: Sarif::Message.new(text: "Test"), level: Sarif::Level::Error),
      ],
      language: "en-US",
      column_kind: Sarif::ColumnKind::UnicodeCodePoints
    )
    restored = Sarif::Run.from_json(run.to_json)
    restored.tool.driver.name.should eq("MyTool")
    restored.results.not_nil!.size.should eq(1)
    restored.language.should eq("en-US")
    restored.column_kind.should eq(Sarif::ColumnKind::UnicodeCodePoints)
  end

  describe "#find_results" do
    it "filters by multiple criteria" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [
          Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1", level: Sarif::Level::Error),
          Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R1", level: Sarif::Level::Warning),
          Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R2", level: Sarif::Level::Error),
        ]
      )
      run.find_results(rule_id: "R1", level: Sarif::Level::Error).size.should eq(1)
      run.find_results(rule_id: "R1").size.should eq(2)
      run.find_results(level: Sarif::Level::Error).size.should eq(2)
      run.find_results.size.should eq(3)
    end

    it "filters by kind" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [
          Sarif::Result.new(message: Sarif::Message.new(text: "A"), kind: Sarif::ResultKind::Pass),
          Sarif::Result.new(message: Sarif::Message.new(text: "B"), kind: Sarif::ResultKind::Fail),
        ]
      )
      run.find_results(kind: Sarif::ResultKind::Pass).size.should eq(1)
    end

    it "returns empty when results is nil" do
      run = Sarif::Run.new(tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")))
      run.find_results(rule_id: "R1").should be_empty
    end
  end

  describe "#result_counts_by_level" do
    it "counts results by level" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [
          Sarif::Result.new(message: Sarif::Message.new(text: "A"), level: Sarif::Level::Error),
          Sarif::Result.new(message: Sarif::Message.new(text: "B"), level: Sarif::Level::Warning),
          Sarif::Result.new(message: Sarif::Message.new(text: "C"), level: Sarif::Level::Error),
        ]
      )
      counts = run.result_counts_by_level
      counts[Sarif::Level::Error].should eq(2)
      counts[Sarif::Level::Warning].should eq(1)
    end
  end

  describe "#result_counts_by_rule_id" do
    it "counts results by rule_id" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [
          Sarif::Result.new(message: Sarif::Message.new(text: "A"), rule_id: "R1"),
          Sarif::Result.new(message: Sarif::Message.new(text: "B"), rule_id: "R2"),
          Sarif::Result.new(message: Sarif::Message.new(text: "C"), rule_id: "R1"),
        ]
      )
      counts = run.result_counts_by_rule_id
      counts["R1"].should eq(2)
      counts["R2"].should eq(1)
    end
  end

  describe "#valid?" do
    it "returns true for valid run" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "issue"))]
      )
      run.valid?.should be_true
    end

    it "returns false when tool driver name is empty" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: ""))
      )
      run.valid?.should be_false
    end

    it "returns false when a result is invalid" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [Sarif::Result.new(message: Sarif::Message.new)]
      )
      run.valid?.should be_false
    end

    it "returns true when results is nil" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))
      )
      run.valid?.should be_true
    end
  end
end
