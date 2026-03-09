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
end
