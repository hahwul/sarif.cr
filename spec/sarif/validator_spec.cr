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

  it "detects empty stack frames" do
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
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("at least one frame")) }.should be_true
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

  # --- Rule ID uniqueness ---

  it "detects duplicate rule IDs within driver.rules" do
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
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("duplicate descriptor id: 'R001'")) }.should be_true
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

  it "detects duplicate notification IDs" do
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
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("duplicate descriptor id")) }.should be_true
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

  it "detects negative artifact parentIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          artifacts: [
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "file.cr"),
              parent_index: -1
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("parentIndex")) }.should be_true
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

  it "detects duplicate rule IDs in tool extensions" do
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
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("duplicate descriptor id: 'EXT001'")) }.should be_true
  end
end
