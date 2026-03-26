require "../spec_helper"

describe Sarif::Validator do
  it "validates a correct SARIF log" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "ValidTool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "Issue")),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
    result.errors.should be_empty
  end

  it "detects empty tool driver name" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: ""))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("name must not be empty")) }.should be_true
  end

  it "detects invalid version" do
    log = Sarif::SarifLog.new(
      version: "1.0.0",
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Unsupported SARIF version")) }.should be_true
  end

  it "detects result message without text or id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("text or id")) }.should be_true
  end

  it "detects invalid ruleIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "issue"), rule_index: 5),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Invalid ruleIndex")) }.should be_true
  end

  it "detects ruleId mismatch with ruleIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              rules: [Sarif::ReportingDescriptor.new(id: "R001")]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_id: "R999", rule_index: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("does not match")) }.should be_true
  end

  it "detects invalid region startLine" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("startLine must be >= 1")) }.should be_true
  end

  it "detects invalid region startColumn" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 1, start_column: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("startColumn must be >= 1")) }.should be_true
  end

  it "detects endColumn < startColumn on same line" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 5, end_line: 5, start_column: 10, end_column: 3)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("endColumn")) }.should be_true
  end

  it "detects invalid region in relatedLocations" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              related_locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path.includes?("relatedLocations") }.should be_true
  end

  it "detects endLine < startLine" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 10, end_line: 5)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("endLine")) }.should be_true
  end

  it "provides error path information" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "")),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.errors[0].path.should eq("$.runs[0].tool.driver.name")
  end

  it "detects invalid GUID format" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              guid: "not-a-uuid"
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Invalid GUID format")) }.should be_true
  end

  it "accepts valid GUID format" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              guid: "550e8400-e29b-41d4-a716-446655440000"
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects invalid timestamp format" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              start_time_utc: "2024-01-01 12:00:00"
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Invalid timestamp format")) }.should be_true
  end

  it "accepts valid RFC 3339 timestamp" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              start_time_utc: "2024-01-01T12:00:00Z"
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects rank out of range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rank: 101.0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("rank must be between")) }.should be_true
  end

  it "detects negative rank" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rank: -1.0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
  end

  it "detects invalid occurrenceCount" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              occurrence_count: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("occurrenceCount must be >= 1")) }.should be_true
  end

  it "detects invalid URI format" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              download_uri: "not a uri"
            )
          ),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Invalid URI format")) }.should be_true
  end

  it "accepts valid URI format" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              download_uri: "https://example.com/tool"
            )
          ),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects empty reporting descriptor id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              rules: [Sarif::ReportingDescriptor.new(id: "")]
            )
          ),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("id must not be empty")) }.should be_true
  end

  it "detects endTimeUtc before startTimeUtc" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              start_time_utc: "2024-01-02T00:00:00Z",
              end_time_utc: "2024-01-01T00:00:00Z"
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("endTimeUtc must not be before startTimeUtc")) }.should be_true
  end

  it "detects empty codeFlow threadFlows" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              code_flows: [
                Sarif::CodeFlow.new(thread_flows: [] of Sarif::ThreadFlow),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("at least one threadFlow")) }.should be_true
  end

  it "detects empty fix artifactChanges" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              fixes: [
                Sarif::Fix.new(artifact_changes: [] of Sarif::ArtifactChange),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("at least one artifactChange")) }.should be_true
  end

  it "detects empty versionControlProvenance repositoryUri" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          version_control_provenance: [
            Sarif::VersionControlDetails.new(repository_uri: ""),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("repositoryUri must not be empty")) }.should be_true
  end

  it "detects validation depth exceeding max_depth" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "issue")),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new(max_depth: 1).validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("exceeds maximum allowed depth")) }.should be_true
  end

  it "passes validation when within max_depth" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "issue")),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new(max_depth: 100).validate(log)
    result.valid?.should be_true
  end

  it "validates tool extensions" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(name: "Tool"),
            extensions: [Sarif::ToolComponent.new(name: "")]
          ),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path.includes?("extensions[0]") }.should be_true
  end
end
