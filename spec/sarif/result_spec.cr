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
end
