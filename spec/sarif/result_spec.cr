require "../spec_helper"

describe Sarif::Result do
  it "creates with required message" do
    result = Sarif::Result.new(message: Sarif::Message.new(text: "An issue"))
    result.message.text.should eq("An issue")
    result.rule_id.should be_nil
    result.level.should be_nil
  end

  it "provides effective_level defaulting to warning" do
    result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))
    result.effective_level.should eq(Sarif::Level::Warning)

    result2 = Sarif::Result.new(message: Sarif::Message.new(text: "test"), level: Sarif::Level::Error)
    result2.effective_level.should eq(Sarif::Level::Error)
  end

  it "provides effective_kind defaulting to fail" do
    result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))
    result.effective_kind.should eq(Sarif::ResultKind::Fail)

    result2 = Sarif::Result.new(message: Sarif::Message.new(text: "test"), kind: Sarif::ResultKind::Pass)
    result2.effective_kind.should eq(Sarif::ResultKind::Pass)
  end

  it "serializes with all fields" do
    result = Sarif::Result.new(
      message: Sarif::Message.new(text: "Unused variable"),
      rule_id: "LINT001",
      rule_index: 0,
      level: Sarif::Level::Warning,
      kind: Sarif::ResultKind::Fail,
      locations: [
        Sarif::Location.new(
          physical_location: Sarif::PhysicalLocation.new(
            artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
            region: Sarif::Region.new(start_line: 10)
          )
        ),
      ],
      fingerprints: {"primary" => "abc123"},
      partial_fingerprints: {"hash/v1" => "def456"}
    )
    json = result.to_json
    parsed = JSON.parse(json)
    parsed["ruleId"].as_s.should eq("LINT001")
    parsed["ruleIndex"].as_i.should eq(0)
    parsed["level"].as_s.should eq("warning")
    parsed["kind"].as_s.should eq("fail")
    parsed["locations"][0]["physicalLocation"]["region"]["startLine"].as_i.should eq(10)
    parsed["fingerprints"]["primary"].as_s.should eq("abc123")
    parsed["partialFingerprints"]["hash/v1"].as_s.should eq("def456")
  end

  it "omits nil fields" do
    result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))
    json = result.to_json
    parsed = JSON.parse(json)
    parsed.as_h.has_key?("ruleId").should be_false
    parsed.as_h.has_key?("level").should be_false
    parsed.as_h.has_key?("locations").should be_false
    parsed.as_h.has_key?("codeFlows").should be_false
  end

  it "round-trips through JSON" do
    result = Sarif::Result.new(
      message: Sarif::Message.new(text: "test issue"),
      rule_id: "R001",
      level: Sarif::Level::Error,
      baseline_state: Sarif::BaselineState::New,
      rank: 85.5,
      work_item_uris: ["https://issues.example.com/1"]
    )
    json = result.to_json
    restored = Sarif::Result.from_json(json)
    restored.message.text.should eq("test issue")
    restored.rule_id.should eq("R001")
    restored.level.should eq(Sarif::Level::Error)
    restored.baseline_state.should eq(Sarif::BaselineState::New)
    restored.rank.should eq(85.5)
    restored.work_item_uris.should eq(["https://issues.example.com/1"])
  end

  it "supports suppressions" do
    result = Sarif::Result.new(
      message: Sarif::Message.new(text: "suppressed"),
      suppressions: [
        Sarif::Suppression.new(kind: Sarif::SuppressionKind::InSource, justification: "reviewed"),
      ]
    )
    json = result.to_json
    parsed = JSON.parse(json)
    parsed["suppressions"][0]["kind"].as_s.should eq("inSource")
    parsed["suppressions"][0]["justification"].as_s.should eq("reviewed")
  end

  describe "#valid?" do
    it "returns true for valid result" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "issue"))
      result.valid?.should be_true
    end

    it "returns false when message has no text or id" do
      result = Sarif::Result.new(message: Sarif::Message.new)
      result.valid?.should be_false
    end

    it "returns false when rank is out of range" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "issue"), rank: 101.0)
      result.valid?.should be_false
    end

    it "returns false when occurrenceCount is less than 1" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "issue"), occurrence_count: 0)
      result.valid?.should be_false
    end

    it "returns true with valid rank and occurrenceCount" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "issue"), rank: 50.0, occurrence_count: 3)
      result.valid?.should be_true
    end
  end

  describe "#effective_level (SARIF 2.1.0 §3.27.10)" do
    it "returns the explicit level when present" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "test"), level: Sarif::Level::Error)
      result.effective_level.should eq(Sarif::Level::Error)
    end

    it "returns none for a pass result with no explicit level" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "test"), kind: Sarif::ResultKind::Pass)
      result.effective_level.should eq(Sarif::Level::None)
    end

    it "returns none for a notApplicable result with no explicit level" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "test"), kind: Sarif::ResultKind::NotApplicable)
      result.effective_level.should eq(Sarif::Level::None)
    end

    it "falls back to warning when kind is fail and no rule context is given" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "test"), kind: Sarif::ResultKind::Fail)
      result.effective_level.should eq(Sarif::Level::Warning)
    end

    it "falls back to warning when kind is absent and no rule context is given" do
      result = Sarif::Result.new(message: Sarif::Message.new(text: "test"))
      result.effective_level.should eq(Sarif::Level::Warning)
    end

    it "inherits the rule's defaultConfiguration.level (resolved by ruleId)" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_id: "RULE001")]
      )
      result = run.results.not_nil!.first
      result.effective_level(run).should eq(Sarif::Level::Error)
    end

    it "inherits the rule's defaultConfiguration.level (resolved by ruleIndex)" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_index: 0)]
      )
      result = run.results.not_nil!.first
      result.effective_level(run).should eq(Sarif::Level::Note)
    end

    it "falls back to warning when the rule cannot be resolved in the run" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_id: "MISSING")]
      )
      result = run.results.not_nil!.first
      result.effective_level(run).should eq(Sarif::Level::Warning)
    end

    it "falls back to warning when the rule has no defaultConfiguration.level" do
      rule = Sarif::ReportingDescriptor.new(id: "RULE001")
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_id: "RULE001")]
      )
      result = run.results.not_nil!.first
      result.effective_level(run).should eq(Sarif::Level::Warning)
    end

    it "still returns none for a non-fail kind even with run context" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_id: "RULE001", kind: Sarif::ResultKind::Pass)]
      )
      result = run.results.not_nil!.first
      result.effective_level(run).should eq(Sarif::Level::None)
    end
  end

  describe "#effective_level configuration overrides (SARIF 2.1.0 §3.27.10)" do
    it "prefers a ruleConfigurationOverride reachable through provenance.invocationIndex" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        invocations: [
          Sarif::Invocation.new(
            execution_successful: true,
            rule_configuration_overrides: [
              Sarif::ConfigurationOverride.new(
                configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error),
                descriptor: Sarif::ReportingDescriptorReference.new(id: "RULE001")
              ),
            ]
          ),
        ],
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"), rule_id: "RULE001",
            provenance: Sarif::ResultProvenance.new(invocation_index: 0)
          ),
        ]
      )
      run.results.not_nil!.first.effective_level(run).should eq(Sarif::Level::Error)
    end

    it "ignores an override for a different rule" do
      rules = [
        Sarif::ReportingDescriptor.new(
          id: "RULE001",
          default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
        ),
        Sarif::ReportingDescriptor.new(id: "RULE002"),
      ]
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: rules)),
        invocations: [
          Sarif::Invocation.new(
            execution_successful: true,
            rule_configuration_overrides: [
              Sarif::ConfigurationOverride.new(
                configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error),
                descriptor: Sarif::ReportingDescriptorReference.new(id: "RULE002")
              ),
            ]
          ),
        ],
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"), rule_id: "RULE001",
            provenance: Sarif::ResultProvenance.new(invocation_index: 0)
          ),
        ]
      )
      run.results.not_nil!.first.effective_level(run).should eq(Sarif::Level::Note)
    end

    it "keeps the rule defaultConfiguration when the named invocation has no overrides" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        invocations: [Sarif::Invocation.new(execution_successful: true)],
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"), rule_id: "RULE001",
            provenance: Sarif::ResultProvenance.new(invocation_index: 0)
          ),
        ]
      )
      run.results.not_nil!.first.effective_level(run).should eq(Sarif::Level::Note)
    end

    it "ignores overrides when invocationIndex is the -1 sentinel" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        invocations: [
          Sarif::Invocation.new(
            execution_successful: true,
            rule_configuration_overrides: [
              Sarif::ConfigurationOverride.new(
                configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error),
                descriptor: Sarif::ReportingDescriptorReference.new(id: "RULE001")
              ),
            ]
          ),
        ],
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"), rule_id: "RULE001",
            provenance: Sarif::ResultProvenance.new(invocation_index: -1)
          ),
        ]
      )
      run.results.not_nil!.first.effective_level(run).should eq(Sarif::Level::Note)
    end

    it "does not raise when invocationIndex is out of range" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"), rule_id: "RULE001",
            provenance: Sarif::ResultProvenance.new(invocation_index: 7)
          ),
        ]
      )
      run.results.not_nil!.first.effective_level(run).should eq(Sarif::Level::Note)
    end
  end

  describe "#resolve_rule (SARIF 2.1.0 §3.27.7)" do
    it "resolves through result.rule into a tool extension" do
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(
          driver: Sarif::ToolComponent.new(name: "Tool"),
          extensions: [
            Sarif::ToolComponent.new(
              name: "Plugin",
              rules: [
                Sarif::ReportingDescriptor.new(
                  id: "EXT001",
                  default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error)
                ),
              ]
            ),
          ]
        ),
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"),
            rule: Sarif::ReportingDescriptorReference.new(
              id: "EXT001", tool_component: Sarif::ToolComponentReference.new(index: 0)
            )
          ),
        ]
      )
      result = run.results.not_nil!.first
      result.resolve_rule(run).not_nil!.id.should eq("EXT001")
      result.effective_level(run).should eq(Sarif::Level::Error)
    end

    it "lets result.rule inherit ruleIndex when rule.index is absent" do
      rule = Sarif::ReportingDescriptor.new(
        id: "RULE001",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Note)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [
          Sarif::Result.new(
            message: Sarif::Message.new(text: "test"), rule_index: 0,
            rule: Sarif::ReportingDescriptorReference.new
          ),
        ]
      )
      run.results.not_nil!.first.resolve_rule(run).not_nil!.id.should eq("RULE001")
    end

    it "resolves a hierarchical ruleId to its descriptor" do
      rule = Sarif::ReportingDescriptor.new(
        id: "CA5350",
        default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Error)
      )
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_id: "CA5350/md5")]
      )
      result = run.results.not_nil!.first
      result.resolve_rule(run).not_nil!.id.should eq("CA5350")
      result.effective_level(run).should eq(Sarif::Level::Error)
    end

    it "falls back to ruleId when ruleIndex is out of range" do
      rule = Sarif::ReportingDescriptor.new(id: "RULE001")
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [
          Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_id: "RULE001", rule_index: 9),
        ]
      )
      run.results.not_nil!.first.resolve_rule(run).not_nil!.id.should eq("RULE001")
    end

    it "does not resolve the -1 ruleIndex sentinel positionally" do
      rule = Sarif::ReportingDescriptor.new(id: "RULE001")
      run = Sarif::Run.new(
        tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool", rules: [rule])),
        results: [Sarif::Result.new(message: Sarif::Message.new(text: "test"), rule_index: -1)]
      )
      run.results.not_nil!.first.resolve_rule(run).should be_nil
    end
  end
end
