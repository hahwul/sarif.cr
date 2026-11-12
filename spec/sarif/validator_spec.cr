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

  it "resolves ruleIndex in the extension named by rule.toolComponent (§3.27.6, §3.52.3)" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(name: "Tool",
              rules: [Sarif::ReportingDescriptor.new(id: "D0")]),
            extensions: [
              Sarif::ToolComponent.new(name: "Plugin", rules: [
                Sarif::ReportingDescriptor.new(id: "E0"),
                Sarif::ReportingDescriptor.new(id: "E1"),
              ]),
            ]
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_id: "E1", rule_index: 1,
              rule: Sarif::ReportingDescriptorReference.new(
                id: "E1", index: 1,
                tool_component: Sarif::ToolComponentReference.new(index: 0)
              )
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.errors.should be_empty
  end

  it "still checks ruleId against the extension rule at ruleIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(name: "Tool",
              rules: [Sarif::ReportingDescriptor.new(id: "D0")]),
            extensions: [
              Sarif::ToolComponent.new(name: "Plugin",
                rules: [Sarif::ReportingDescriptor.new(id: "E0")]),
            ]
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_id: "D0", rule_index: 0,
              rule: Sarif::ReportingDescriptorReference.new(
                tool_component: Sarif::ToolComponentReference.new(index: 0)
              )
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.errors.any? { |e| e.message.try(&.includes?("does not match rule at ruleIndex 0 ('E0')")) }.should be_true
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
    result.errors.any?(&.path.includes?("relatedLocations")).should be_true
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

  it "detects negative rank other than -1.0" do
    [-0.5, -1.5, -100.0].each do |rank|
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            results: [
              Sarif::Result.new(
                message: Sarif::Message.new(text: "issue"),
                rank: rank
              ),
            ]
          ),
        ]
      )
      result = Sarif::Validator.new.validate(log)
      result.valid?.should be_false
      result.errors.any?(&.path.ends_with?(".rank")).should be_true
    end
  end

  it "accepts an explicit rank of -1.0 (unknown; schema minimum -1.0)" do
    log = Sarif.parse(%({"version":"2.1.0","runs":[{"tool":{"driver":{"name":"T","rules":[{"id":"R1","defaultConfiguration":{"rank":-1.0}}]}},"results":[{"ruleId":"R1","message":{"text":"m"},"rank":-1.0}]}]}))
    result = Sarif::Validator.new.validate(log)
    result.errors.select(&.path.includes?("rank")).should be_empty
    log.runs![0].results.not_nil![0].valid?.should be_true
    log.runs![0].tool.driver.rules.not_nil![0].valid?.should be_true
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

  it "orders invocation times as instants, not strings" do
    # "…00Z" sorts after "…00.5Z" as a string, yet is the earlier instant.
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              start_time_utc: "2024-01-01T00:00:00Z",
              end_time_utc: "2024-01-01T00:00:00.5Z"
            ),
          ]
        ),
      ]
    )
    Sarif::Validator.new.validate(log).valid?.should be_true
  end

  it "orders invocation times across offsets" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              start_time_utc: "2024-01-01T10:00:00+09:00",
              end_time_utc: "2024-01-01T02:00:00Z"
            ),
          ]
        ),
      ]
    )
    Sarif::Validator.new.validate(log).valid?.should be_true
  end

  it "does not raise on timestamps Crystal cannot parse and still orders them" do
    ["+99:00", ".0000000001Z"].each do |suffix|
      log = Sarif::SarifLog.new(
        runs: [
          Sarif::Run.new(
            tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
            invocations: [
              Sarif::Invocation.new(
                execution_successful: true,
                start_time_utc: "2025-01-01T00:00:00#{suffix}",
                end_time_utc: "2024-01-01T00:00:00Z"
              ),
            ]
          ),
        ]
      )
      result = Sarif::Validator.new.validate(log)
      result.errors.any? { |e| e.message.try(&.includes?("endTimeUtc must not be before startTimeUtc")) }.should be_true
    end
  end

  it "orders provenance detection times as instants, not strings" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              provenance: Sarif::ResultProvenance.new(
                first_detection_time_utc: "2024-06-01T10:00:00Z",
                last_detection_time_utc: "2024-06-01T10:00:00.123Z"
              )
            ),
          ]
        ),
      ]
    )
    Sarif::Validator.new.validate(log).valid?.should be_true
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
    result.errors.any?(&.path.includes?("extensions[0]")).should be_true
  end

  # "at least one of A or B" constraint validations

  it "detects physicalLocation without artifactLocation or address" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("artifactLocation or address")) }.should be_true
  end

  it "accepts physicalLocation with artifactLocation" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr")
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "accepts physicalLocation with address" do
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
                    address: Sarif::Address.new(absolute_address: 0x1000_i64)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects graphTraversal without runGraphIndex or resultGraphIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              graph_traversals: [
                Sarif::GraphTraversal.new,
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("runGraphIndex or resultGraphIndex")) }.should be_true
  end

  it "accepts graphTraversal with runGraphIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              graph_traversals: [
                Sarif::GraphTraversal.new(run_graph_index: 0),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects externalPropertyFileReference without location or guid" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          external_property_file_references: Sarif::ExternalPropertyFileReferences.new(
            driver: Sarif::ExternalPropertyFileReference.new
          )
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("location or guid")) }.should be_true
  end

  it "accepts externalPropertyFileReference with guid" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          external_property_file_references: Sarif::ExternalPropertyFileReferences.new(
            driver: Sarif::ExternalPropertyFileReference.new(
              guid: "550e8400-e29b-41d4-a716-446655440000"
            )
          )
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # minItems / non-empty constraint validations

  it "accepts a stack with zero frames (§3.44.3)" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              stacks: [
                Sarif::Stack.new(frames: [] of Sarif::StackFrame),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects empty node id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(nodes: [Sarif::Node.new(id: "")]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("node id must not be empty")) }.should be_true
  end

  it "caps validate_node recursion at max_depth instead of overflowing the stack" do
    # Build a deeply nested chain of children. With no depth check the
    # validator would recurse `depth` levels and crash on a hostile SARIF.
    depth = 50
    leaf = Sarif::Node.new(id: "leaf")
    chain = (0...depth).reverse_each.reduce(leaf) do |child, i|
      Sarif::Node.new(id: "n#{i}", children: [child])
    end

    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [Sarif::Graph.new(nodes: [chain])]
        ),
      ]
    )

    result = Sarif::Validator.new(max_depth: 10).validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("exceeds maximum allowed depth")) }.should be_true
  end

  it "detects empty edge id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(edges: [Sarif::Edge.new(id: "", source_node_id: "a", target_node_id: "b")]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("edge id must not be empty")) }.should be_true
  end

  it "detects empty edge sourceNodeId" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(edges: [Sarif::Edge.new(id: "e1", source_node_id: "", target_node_id: "b")]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("sourceNodeId must not be empty")) }.should be_true
  end

  it "detects empty edge targetNodeId" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(edges: [Sarif::Edge.new(id: "e1", source_node_id: "a", target_node_id: "")]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("targetNodeId must not be empty")) }.should be_true
  end

  # reportingConfiguration.rank validation

  it "detects reportingConfiguration rank out of range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              rules: [
                Sarif::ReportingDescriptor.new(
                  id: "R001",
                  default_configuration: Sarif::ReportingConfiguration.new(rank: 101.0)
                ),
              ]
            )
          ),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path.includes?("defaultConfiguration") && e.message.try(&.includes?("rank")) }.should be_true
  end

  it "accepts reportingConfiguration rank within range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              rules: [
                Sarif::ReportingDescriptor.new(
                  id: "R001",
                  default_configuration: Sarif::ReportingConfiguration.new(rank: 50.0)
                ),
              ]
            )
          ),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # Graph node/edge ID uniqueness validation

  it "detects duplicate node ids" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(nodes: [
              Sarif::Node.new(id: "n1"),
              Sarif::Node.new(id: "n1"),
            ]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("duplicate node id")) }.should be_true
  end

  it "detects duplicate edge ids" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(edges: [
              Sarif::Edge.new(id: "e1", source_node_id: "a", target_node_id: "b"),
              Sarif::Edge.new(id: "e1", source_node_id: "c", target_node_id: "d"),
            ]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("duplicate edge id")) }.should be_true
  end

  it "detects duplicate node ids in children" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(nodes: [
              Sarif::Node.new(id: "n1", children: [
                Sarif::Node.new(id: "n1"),
              ]),
            ]),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("duplicate node id")) }.should be_true
  end

  it "accepts graph with unique ids" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(
              nodes: [Sarif::Node.new(id: "n1"), Sarif::Node.new(id: "n2")],
              edges: [Sarif::Edge.new(id: "e1", source_node_id: "n1", target_node_id: "n2")]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # Index reference validation

  it "detects artifact index out of range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(location: Sarif::ArtifactLocation.new(uri: "file.cr")),
          ],
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr", index: 5)
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
    result.errors.any? { |e| e.message.try(&.includes?("artifact index")) }.should be_true
  end

  it "detects logicalLocation index out of range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          logical_locations: [
            Sarif::LogicalLocation.new(name: "func1"),
          ],
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  logical_locations: [
                    Sarif::LogicalLocation.new(name: "func2", index: 10),
                  ]
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("logicalLocation index")) }.should be_true
  end

  it "accepts valid artifact index reference" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(location: Sarif::ArtifactLocation.new(uri: "file.cr")),
          ],
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr", index: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects analysisTarget artifact index out of range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(location: Sarif::ArtifactLocation.new(uri: "file.cr")),
          ],
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              analysis_target: Sarif::ArtifactLocation.new(uri: "file.cr", index: 99)
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("artifact index")) }.should be_true
  end

  # --- Rule ID uniqueness (not required: §3.19.23, §3.19.24) ---

  it "allows duplicate rule IDs within driver.rules (§3.19.23)" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(
            name: "Tool",
            rules: [
              Sarif::ReportingDescriptor.new(id: "R001"),
              Sarif::ReportingDescriptor.new(id: "R002"),
              Sarif::ReportingDescriptor.new(id: "R001"),
            ]
          ))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "allows unique rule IDs" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(
            name: "Tool",
            rules: [
              Sarif::ReportingDescriptor.new(id: "R001"),
              Sarif::ReportingDescriptor.new(id: "R002"),
              Sarif::ReportingDescriptor.new(id: "R003"),
            ]
          ))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "allows duplicate notification IDs (§3.19.24)" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(
            name: "Tool",
            notifications: [
              Sarif::ReportingDescriptor.new(id: "N001"),
              Sarif::ReportingDescriptor.new(id: "N001"),
            ]
          ))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- Edge→Node reference integrity ---

  it "detects edge referencing unknown source node" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(
              nodes: [Sarif::Node.new(id: "n1"), Sarif::Node.new(id: "n2")],
              edges: [Sarif::Edge.new(id: "e1", source_node_id: "n999", target_node_id: "n2")]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("sourceNodeId 'n999' references unknown node")) }.should be_true
  end

  it "detects edge referencing unknown target node" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(
              nodes: [Sarif::Node.new(id: "n1")],
              edges: [Sarif::Edge.new(id: "e1", source_node_id: "n1", target_node_id: "n_missing")]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("targetNodeId 'n_missing' references unknown node")) }.should be_true
  end

  it "allows edges referencing valid nodes" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(
              nodes: [Sarif::Node.new(id: "n1"), Sarif::Node.new(id: "n2")],
              edges: [Sarif::Edge.new(id: "e1", source_node_id: "n1", target_node_id: "n2")]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- Artifact parentIndex bounds ---

  it "detects artifact parentIndex out of range" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(location: Sarif::ArtifactLocation.new(uri: "dir/")),
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "dir/file.cr"),
              parent_index: 99
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("parentIndex")) }.should be_true
  end

  it "detects out-of-range negative artifact parentIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "file.cr"),
              parent_index: -2
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("parentIndex must be >= -1")) }.should be_true
  end

  # -1 is the schema default for parentIndex and means "no parent" (SARIF 2.1.0
  # §3.24, `"default": -1, "minimum": -1`).
  it "accepts the -1 parentIndex sentinel" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(location: Sarif::ArtifactLocation.new(uri: "dir/")),
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "file.cr"),
              parent_index: -1
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "allows valid artifact parentIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(location: Sarif::ArtifactLocation.new(uri: "dir/")),
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "dir/file.cr"),
              parent_index: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- ResultProvenance time ordering ---

  it "detects provenance lastDetectionTimeUtc before firstDetectionTimeUtc" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              provenance: Sarif::ResultProvenance.new(
                first_detection_time_utc: "2024-06-01T00:00:00Z",
                last_detection_time_utc: "2024-01-01T00:00:00Z"
              )
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("lastDetectionTimeUtc must not be before")) }.should be_true
  end

  it "allows valid provenance time ordering" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              provenance: Sarif::ResultProvenance.new(
                first_detection_time_utc: "2024-01-01T00:00:00Z",
                last_detection_time_utc: "2024-06-01T00:00:00Z"
              )
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "validates provenance GUID format" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              provenance: Sarif::ResultProvenance.new(
                first_detection_run_guid: "not-a-guid"
              )
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Invalid GUID format")) }.should be_true
  end

  # --- Exception depth protection ---

  it "limits exception innerExceptions depth" do
    # Build deeply nested exceptions
    inner = Sarif::SarifException.new(kind: "deepest", message: "bottom")
    150.times do
      inner = Sarif::SarifException.new(kind: "wrapper", inner_exceptions: [inner])
    end

    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: false,
              tool_execution_notifications: [
                Sarif::Notification.new(
                  message: Sarif::Message.new(text: "error"),
                  sarif_exception: inner
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new(max_depth: 10).validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("exceeds maximum allowed depth")) }.should be_true
  end

  # --- Self-referencing parentIndex ---

  it "detects artifact with self-referencing parentIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "file.cr"),
              parent_index: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("parentIndex")) }.should be_true
  end

  # --- Edge validation with edges-only graph ---

  it "allows edges-only graph without nodes" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [
            Sarif::Graph.new(
              edges: [Sarif::Edge.new(id: "e1", source_node_id: "n1", target_node_id: "n2")]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- Duplicate rule IDs in extensions ---

  it "allows duplicate rule IDs in tool extensions (§3.19.23)" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(name: "Tool"),
            extensions: [
              Sarif::ToolComponent.new(
                name: "Plugin",
                rules: [
                  Sarif::ReportingDescriptor.new(id: "EXT001"),
                  Sarif::ReportingDescriptor.new(id: "EXT001"),
                ]
              ),
            ]
          )
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- Index sentinels (SARIF 2.1.0 §3.27.6, §3.52.5) ---

  it "accepts the -1 ruleIndex sentinel" do
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
              rule_id: "R001", rule_index: -1
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects a ruleIndex below the -1 sentinel" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "issue"), rule_index: -2),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("ruleIndex must be >= -1")) }.should be_true
  end

  # --- Hierarchical ruleId (SARIF 2.1.0 §3.27.5, §3.52.4, §3.5.4.1) ---

  it "accepts a ruleId that extends the descriptor id by one hierarchical component" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "CodeScanner",
              rules: [Sarif::ReportingDescriptor.new(id: "CA5350")]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_id: "CA5350/md5", rule_index: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  it "detects a ruleId that adds more than one hierarchical component" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "CodeScanner",
              rules: [Sarif::ReportingDescriptor.new(id: "CA5350")]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_id: "CA5350/md5/weak", rule_index: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("does not match rule at ruleIndex")) }.should be_true
  end

  # --- rule reference consistency (SARIF 2.1.0 §3.27.7) ---

  it "detects rule.id that disagrees with ruleId" do
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
              rule_id: "R001",
              rule: Sarif::ReportingDescriptorReference.new(id: "R002", index: 0)
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("must equal ruleId")) }.should be_true
  end

  it "detects rule.index that disagrees with ruleIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              rules: [
                Sarif::ReportingDescriptor.new(id: "R001"),
                Sarif::ReportingDescriptor.new(id: "R002"),
              ]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_index: 0,
              rule: Sarif::ReportingDescriptorReference.new(index: 1)
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("must equal ruleIndex")) }.should be_true
  end

  # --- Unknown enum values (SARIF 2.1.0 §3.27.9, §3.27.10) ---

  it "detects an enum value outside the SARIF 2.1.0 vocabulary" do
    json = <<-JSON
      {
        "version": "2.1.0",
        "runs": [
          {
            "tool": {"driver": {"name": "Tool"}},
            "results": [{"message": {"text": "issue"}, "level": "critical"}]
          }
        ]
      }
      JSON
    log = Sarif.parse(json)
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path == "$.runs[0].results[0].level" }.should be_true
  end

  it "detects an unknown kind and baselineState" do
    json = <<-JSON
      {
        "version": "2.1.0",
        "runs": [
          {
            "tool": {"driver": {"name": "Tool"}},
            "results": [
              {"message": {"text": "issue"}, "kind": "bogus", "baselineState": "bogus"}
            ]
          }
        ]
      }
      JSON
    log = Sarif.parse(json)
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path == "$.runs[0].results[0].kind" }.should be_true
    result.errors.any? { |e| e.path == "$.runs[0].results[0].baselineState" }.should be_true
  end

  it "detects an unknown columnKind" do
    json = <<-JSON
      {
        "version": "2.1.0",
        "runs": [{"tool": {"driver": {"name": "Tool"}}, "columnKind": "bogus"}]
      }
      JSON
    log = Sarif.parse(json)
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path == "$.runs[0].columnKind" }.should be_true
  end

  it "accepts every known enum value" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          column_kind: Sarif::ColumnKind::Utf16CodeUnits,
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              level: Sarif::Level::Error,
              kind: Sarif::ResultKind::Fail,
              baseline_state: Sarif::BaselineState::New,
              suppressions: [Sarif::Suppression.new(kind: Sarif::SuppressionKind::External)]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- contextRegion (SARIF 2.1.0 §3.29.5) ---

  it "detects an invalid contextRegion" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                    region: Sarif::Region.new(start_line: 10),
                    context_region: Sarif::Region.new(start_line: 0)
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
    result.errors.any?(&.path.includes?("contextRegion.startLine")).should be_true
  end

  it "detects a contextRegion without a region" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                    context_region: Sarif::Region.new(start_line: 5)
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
    result.errors.any? { |e| e.message.try(&.includes?("contextRegion must be absent")) }.should be_true
  end

  # --- Regions nested in codeFlows, fixes, stacks and annotations ---

  it "detects an invalid region inside a threadFlowLocation" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              code_flows: [
                Sarif::CodeFlow.new(
                  thread_flows: [
                    Sarif::ThreadFlow.new(
                      locations: [
                        Sarif::ThreadFlowLocation.new(
                          location: Sarif::Location.new(
                            physical_location: Sarif::PhysicalLocation.new(
                              artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                              region: Sarif::Region.new(start_line: 0)
                            )
                          )
                        ),
                      ]
                    ),
                  ]
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

  it "detects an invalid deletedRegion inside a fix" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              fixes: [
                Sarif::Fix.new(
                  artifact_changes: [
                    Sarif::ArtifactChange.new(
                      artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                      replacements: [
                        Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 5, end_line: 2)),
                      ]
                    ),
                  ]
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any?(&.path.includes?("deletedRegion")).should be_true
  end

  it "detects an invalid location inside a stack frame" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              stacks: [
                Sarif::Stack.new(
                  frames: [
                    Sarif::StackFrame.new(
                      location: Sarif::Location.new(
                        physical_location: Sarif::PhysicalLocation.new
                      )
                    ),
                  ]
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("artifactLocation or address")) }.should be_true
  end

  it "detects an invalid annotation region on a location" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr")
                  ),
                  annotations: [Sarif::Region.new(start_column: 0)]
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any?(&.path.includes?("annotations[0].startColumn")).should be_true
  end

  # --- Binary/character region offsets ---

  it "detects negative region offsets and lengths" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                    region: Sarif::Region.new(byte_offset: -2, byte_length: -1, char_offset: -3, char_length: -1)
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
    result.errors.any? { |e| e.message.try(&.includes?("byteOffset must be >= -1")) }.should be_true
    result.errors.any? { |e| e.message.try(&.includes?("byteLength must be >= 0")) }.should be_true
    result.errors.any? { |e| e.message.try(&.includes?("charOffset must be >= -1")) }.should be_true
    result.errors.any? { |e| e.message.try(&.includes?("charLength must be >= 0")) }.should be_true
  end

  it "accepts the -1 region offset sentinels" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                    region: Sarif::Region.new(byte_offset: -1, char_offset: -1)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- Notifications ---

  it "detects a notification message without text or id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              tool_execution_notifications: [
                Sarif::Notification.new(message: Sarif::Message.new, time_utc: "not-a-time"),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Notification message must have either text or id")) }.should be_true
    result.errors.any?(&.path.includes?("timeUtc")).should be_true
  end

  # --- Suppressions ---

  it "detects an invalid suppression guid" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              suppressions: [
                Sarif::Suppression.new(kind: Sarif::SuppressionKind::InSource, guid: "not-a-guid"),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path == "$.runs[0].results[0].suppressions[0].guid" }.should be_true
  end

  # --- Spec-compliance regressions ---

  it "rejects a graphTraversal with both runGraphIndex and resultGraphIndex (§3.42.2)" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              graph_traversals: [Sarif::GraphTraversal.new(run_graph_index: 0, result_graph_index: 0)]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("exactly one of runGraphIndex or resultGraphIndex")) }.should be_true
  end

  it "rejects a region that defines neither a text nor a binary region (§3.30.1)" do
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
                    artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                    region: Sarif::Region.new(char_length: 1)
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
    result.errors.map(&.path).should contain("$.runs[0].results[0].locations[0].physicalLocation.region")
  end

  it "validates locations in graph nodes, notifications and run.threadFlowLocations" do
    bad = Sarif::Location.new(physical_location: Sarif::PhysicalLocation.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
      region: Sarif::Region.new(start_line: 0)
    ))
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          graphs: [Sarif::Graph.new(nodes: [Sarif::Node.new(id: "n", location: bad)])],
          thread_flow_locations: [Sarif::ThreadFlowLocation.new(location: bad)],
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              tool_execution_notifications: [
                Sarif::Notification.new(message: Sarif::Message.new(text: "n"), locations: [bad]),
              ]
            ),
          ]
        ),
      ]
    )
    paths = Sarif::Validator.new.validate(log).errors.map(&.path)
    paths.should contain("$.runs[0].graphs[0].nodes[0].location.physicalLocation.region.startLine")
    paths.should contain("$.runs[0].threadFlowLocations[0].location.physicalLocation.region.startLine")
    paths.should contain("$.runs[0].invocations[0].toolExecutionNotifications[0].locations[0].physicalLocation.region.startLine")
  end

  it "rejects a negative artifact offset (schema minimum 0)" do
    log = Sarif.parse(%({"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "x"}},
      "artifacts": [{"offset": -5}, {"offset": 0}]}]}))
    result = Sarif::Validator.new.validate(log)
    result.errors.map(&.path).should eq(["$.runs[0].artifacts[0].offset"])
  end

  describe "pass 2026-11-12 regressions" do
    validate = ->(results : String, extra : String) do
      json = %({"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "x",
        "rules": [{"id": "abc/def"}]}}, "results": [#{results}]#{extra}}]})
      Sarif::Validator.new.validate(Sarif.parse(json)).errors.map { |e| {e.path, e.message} }
    end

    it "rejects a GUID without an RFC 4122 version and variant (§3.5.3, schema pattern)" do
      errors = validate.call(%({"message": {"text": "m"}, "guid": "22222222-2222-2222-2222-222222222222"}), "")
      errors.map(&.[0]).should eq(["$.runs[0].results[0].guid"])
      validate.call(%({"message": {"text": "m"}, "guid": "11111111-1111-1111-8888-111111111111"}), "").should be_empty
    end

    it "checks automationDetails and runAggregates GUIDs" do
      errors = validate.call("", %(, "automationDetails": {"guid": "nope"},
        "runAggregates": [{"correlationGuid": "nope"}]))
      errors.map(&.[0]).should eq(["$.runs[0].automationDetails.guid", "$.runs[0].runAggregates[0].correlationGuid"])
    end

    it "applies the §3.52.4 EXAMPLE to rule.id and rule.index without ruleIndex" do
      results = [
        %({"ruleId": "abc/def", "rule": {"index": 0}, "message": {"text": "valid"}}),
        %({"rule": {"id": "abc/def/ghi", "index": 0}, "message": {"text": "valid"}}),
        %({"rule": {"id": "abc/defg", "index": 0}, "message": {"text": "invalid prefix"}}),
        %({"ruleId": "abc/def", "rule": {"id": "abc/def/ghi", "index": 0}, "message": {"text": "invalid: not equal"}}),
      ].join(",")
      errors = validate.call(results, "")
      errors.map(&.[0]).should eq(["$.runs[0].results[2].rule.id", "$.runs[0].results[3].rule.id"])
    end

    it "rejects a rule.index that addresses no rule" do
      errors = validate.call(%({"rule": {"index": 3}, "message": {"text": "m"}}), "")
      errors.should eq([{"$.runs[0].results[0].rule.index", "Invalid rule.index: 3"}])
    end

    it "reports a rule.index below -1 once" do
      errors = validate.call(%({"rule": {"index": -2}, "message": {"text": "m"}}), "")
      errors.map(&.[0]).should eq(["$.runs[0].results[0].rule.index"])
    end

    it "requires index, guid or id on every reportingDescriptorReference (schema anyOf)" do
      result = %({"message": {"text": "m"}, "rule": {}, "taxa": [{"toolComponent": {"index": 0}}]})
      notification = %({"message": {"text": "n"}, "descriptor": {}, "associatedRule": {"guid": "bad"}})
      extra = %(, "invocations": [{"executionSuccessful": true,
        "ruleConfigurationOverrides": [{"descriptor": {}, "configuration": {"level": "error"}}],
        "toolExecutionNotifications": [#{notification}]}])
      errors = validate.call(result, extra).map(&.[0])
      errors.should eq([
        "$.runs[0].results[0].rule",
        "$.runs[0].results[0].taxa[0]",
        "$.runs[0].invocations[0].ruleConfigurationOverrides[0].descriptor",
        "$.runs[0].invocations[0].toolExecutionNotifications[0].descriptor",
        "$.runs[0].invocations[0].toolExecutionNotifications[0].associatedRule.guid",
      ])
    end

    it "accepts a rule that only names its toolComponent when ruleId or ruleIndex identify it" do
      json = %({"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "x"},
        "extensions": [{"name": "ext", "rules": [{"id": "E0"}]}]},
        "results": [{"ruleId": "E0", "ruleIndex": 0, "rule": {"toolComponent": {"index": 0}}, "message": {"text": "m"}}]}]})
      Sarif::Validator.new.validate(Sarif.parse(json)).errors.should be_empty
    end

    it "rejects a rule.toolComponent that resolves to nothing" do
      errors = validate.call(%({"rule": {"id": "R", "index": 0, "toolComponent": {"index": 5}}, "message": {"text": "m"}}), "")
      errors.map(&.[0]).should eq(["$.runs[0].results[0].rule.toolComponent"])
    end

    it "checks ruleId against the descriptor even when rule.id is present" do
      errors = validate.call(%({"ruleId": "zzz", "ruleIndex": 0, "rule": {"id": "abc/def"}, "message": {"text": "m"}}), "")
      errors.map(&.[0]).should eq(["$.runs[0].results[0].ruleId", "$.runs[0].results[0].rule.id"])
    end

    it "does not add a kind/level error for values outside the vocabulary" do
      results = %({"kind": "review2", "level": "warning", "message": {"text": "m"}}, {"kind": "pass", "level": "fatal", "message": {"text": "m"}})
      validate.call(results, "").map(&.[0]).should eq(["$.runs[0].results[0].kind", "$.runs[0].results[1].level"])
    end

    it "checks reportingDescriptor relationship targets" do
      json = %({"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "x",
        "rules": [{"id": "R", "relationships": [{"target": {}}, {"target": {"guid": "bad"}}]}]}}}]})
      paths = Sarif::Validator.new.validate(Sarif.parse(json)).errors.map(&.path)
      paths.should eq([
        "$.runs[0].tool.driver.rules[0].relationships[0].target",
        "$.runs[0].tool.driver.rules[0].relationships[1].target.guid",
      ])
    end

    it "requires level none when kind is not fail (§3.27.10)" do
      results = [
        %({"kind": "pass", "level": "error", "message": {"text": "m"}}),
        %({"kind": "pass", "level": "none", "message": {"text": "m"}}),
        %({"kind": "informational", "message": {"text": "m"}}),
        %({"kind": "fail", "level": "note", "message": {"text": "m"}}),
      ].join(",")
      validate.call(results, "").map(&.[0]).should eq(["$.runs[0].results[0].level"])
    end

    it "checks schema minimums on locations and thread flow locations" do
      tfl = %({"index": -2, "nestingLevel": -1, "executionOrder": -2})
      result = %({"message": {"text": "m"}, "locations": [{"id": -2, "relationships": [{"target": -1}]}],
        "codeFlows": [{"threadFlows": [{"locations": [#{tfl}]}]}]})
      errors = validate.call(result, %(, "threadFlowLocations": [{"nestingLevel": -1}])).map(&.[0])
      errors.should eq([
        "$.runs[0].results[0].locations[0].id",
        "$.runs[0].results[0].locations[0].relationships[0].target",
        "$.runs[0].results[0].codeFlows[0].threadFlows[0].locations[0].index",
        "$.runs[0].results[0].codeFlows[0].threadFlows[0].locations[0].nestingLevel",
        "$.runs[0].results[0].codeFlows[0].threadFlows[0].locations[0].executionOrder",
        "$.runs[0].threadFlowLocations[0].nestingLevel",
      ])
      ok = %({"message": {"text": "m"}, "locations": [{"id": -1, "relationships": [{"target": 0}]}]})
      validate.call(ok, "").should be_empty
    end

    it "checks workItemUris, hostedViewerUri and deprecatedGuids" do
      json = %({"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "x",
        "rules": [{"id": "R", "deprecatedGuids": ["bad"]}]}},
        "results": [{"message": {"text": "m"}, "workItemUris": ["not a uri"], "hostedViewerUri": "relative/path"}]}]})
      paths = Sarif::Validator.new.validate(Sarif.parse(json)).errors.map(&.path)
      paths.should eq([
        "$.runs[0].tool.driver.rules[0].deprecatedGuids[0]",
        "$.runs[0].results[0].hostedViewerUri",
        "$.runs[0].results[0].workItemUris[0]",
      ])
    end
  end

  describe "message arguments (SARIF 2.1.0 §3.11.11)" do
    argument_errors = ->(json : String) do
      Sarif::Validator.new.validate(Sarif.parse(json)).errors.select(&.path.ends_with?(".arguments")).map(&.path)
    end
    wrap = ->(results : String, extra : String) do
      %({"version":"2.1.0","runs":[{"tool":{"driver":{"name":"T"#{extra}}},"results":[#{results}]}]})
    end

    it "requires n+1 arguments for a {n} placeholder in text or markdown" do
      argument_errors.call(wrap.call(%({"message":{"text":"a {0} b {1}","arguments":["x"]}}), "")).should eq(["$.runs[0].results[0].message.arguments"])
      argument_errors.call(wrap.call(%({"message":{"text":"a {0}"}}), "")).should eq(["$.runs[0].results[0].message.arguments"])
      argument_errors.call(wrap.call(%({"message":{"text":"a {0}","markdown":"**{2}**","arguments":["x","y"]}}), "")).size.should eq(1)
      argument_errors.call(wrap.call(%({"message":{"text":"a {1} {0} {1}","arguments":["x","y"]}}), "")).should be_empty
    end

    it "treats {{ and }} as escaped braces, not placeholders" do
      argument_errors.call(wrap.call(%({"message":{"text":"literal {{0}} and {{{0}}}","arguments":["x"]}}), "")).should be_empty
      argument_errors.call(wrap.call(%({"message":{"text":"literal {{0}} only"}}), "")).should be_empty
      argument_errors.call(wrap.call(%({"message":{"text":"not placeholders: {} {x} {-1} {0"}}), "")).should be_empty
      argument_errors.call(wrap.call(%({"message":{"text":"{{{1}}}","arguments":["x"]}}), "")).size.should eq(1)
    end

    it "counts the string message.id names in the rule's messageStrings" do
      rules = %(,"rules":[{"id":"R1","messageStrings":{"m":{"text":"{0}: {1}"}}}])
      argument_errors.call(wrap.call(%({"ruleId":"R1","ruleIndex":0,"message":{"id":"m","arguments":["x"]}}), rules)).size.should eq(1)
      argument_errors.call(wrap.call(%({"ruleId":"R1","message":{"id":"m","arguments":["x"]}}), rules)).size.should eq(1)
      argument_errors.call(wrap.call(%({"ruleId":"R1","message":{"id":"m","arguments":["x","y"]}}), rules)).should be_empty
      # text does not exempt the id string (§3.11.11 "any of ... text, markdown, or id")
      argument_errors.call(wrap.call(%({"ruleId":"R1","message":{"text":"done","id":"m"}}), rules)).size.should eq(1)
    end

    it "falls back to globalMessageStrings and ignores ids it cannot resolve" do
      global = %(,"globalMessageStrings":{"g":{"text":"x","markdown":"{3}"}})
      argument_errors.call(wrap.call(%({"message":{"id":"g","arguments":["a","b","c"]}}), global)).size.should eq(1)
      argument_errors.call(wrap.call(%({"message":{"id":"g","arguments":["a","b","c","d"]}}), global)).should be_empty
      argument_errors.call(wrap.call(%({"message":{"id":"missing"}}), global)).should be_empty
    end

    it "prefers the rule's messageStrings over globalMessageStrings" do
      extra = %(,"rules":[{"id":"R1","messageStrings":{"m":{"text":"{0}"}}}],"globalMessageStrings":{"m":{"text":"{5}"}})
      argument_errors.call(wrap.call(%({"ruleId":"R1","message":{"id":"m","arguments":["x"]}}), extra)).should be_empty
    end

    it "checks notification messages against the descriptor's messageStrings" do
      json = %({"version":"2.1.0","runs":[{"tool":{"driver":{"name":"T","notifications":[{"id":"N1","messageStrings":{"m":{"text":"{0} {1}"}}}]}},) +
             %("invocations":[{"executionSuccessful":true,"toolExecutionNotifications":[{"descriptor":{"index":0},"message":{"id":"m","arguments":["x"]}}]}]}]})
      argument_errors.call(json).should eq(["$.runs[0].invocations[0].toolExecutionNotifications[0].message.arguments"])
    end

    it "resolves notification descriptors by guid after a dangling index, and by id alone" do
      guid = "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d"
      head = %({"version":"2.1.0","runs":[{"tool":{"driver":{"name":"T","notifications":[{"id":"N1","guid":"#{guid}","messageStrings":{"m":{"text":"{0} {1}"}}}]}},)
      [%({"index":5,"guid":"#{guid}"}), %({"id":"N1"})].each do |descriptor|
        json = head + %("invocations":[{"executionSuccessful":true,"toolExecutionNotifications":[{"descriptor":#{descriptor},"message":{"id":"m","arguments":["x"]}}]}]}]})
        argument_errors.call(json).size.should eq(1)
      end
    end

    it "checks nested messages such as location.message" do
      argument_errors.call(wrap.call(%({"message":{"text":"m"},"locations":[{"message":{"text":"{0}"}}]}), "")).should eq(["$.runs[0].results[0].locations[0].message.arguments"])
      argument_errors.call(wrap.call(%({"message":{"text":"m"},"graphs":[{"nodes":[{"id":"n","label":{"text":"{1}"}}]}]}), "")).should eq(["$.runs[0].results[0].graphs[0].nodes[0].label.arguments"])
    end
  end
end
