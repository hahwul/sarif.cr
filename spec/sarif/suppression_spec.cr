require "../spec_helper"

describe Sarif::Suppression do
  it "creates with kind" do
    s = Sarif::Suppression.new(kind: Sarif::SuppressionKind::InSource)
    s.kind.should eq(Sarif::SuppressionKind::InSource)
    s.status.should be_nil
    s.justification.should be_nil
  end

  it "creates with full details" do
    s = Sarif::Suppression.new(
      kind: Sarif::SuppressionKind::External,
      status: Sarif::SuppressionStatus::Accepted,
      guid: "guid-123",
      justification: "False positive confirmed by security team"
    )
    s.kind.should eq(Sarif::SuppressionKind::External)
    s.status.should eq(Sarif::SuppressionStatus::Accepted)
    s.guid.should eq("guid-123")
    s.justification.should eq("False positive confirmed by security team")
  end

  it "serializes enum values correctly" do
    s = Sarif::Suppression.new(
      kind: Sarif::SuppressionKind::InSource,
      status: Sarif::SuppressionStatus::UnderReview
    )
    json = s.to_json
    parsed = JSON.parse(json)
    parsed["kind"].as_s.should eq("inSource")
    parsed["status"].as_s.should eq("underReview")
  end

  it "supports location" do
    s = Sarif::Suppression.new(
      kind: Sarif::SuppressionKind::InSource,
      location: Sarif::Location.new(
        physical_location: Sarif::PhysicalLocation.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
          region: Sarif::Region.new(start_line: 5)
        )
      )
    )
    s.location.not_nil!.physical_location.not_nil!.artifact_location.not_nil!.uri.should eq("file.cr")
  end

  it "round-trips through JSON" do
    s = Sarif::Suppression.new(
      kind: Sarif::SuppressionKind::External,
      status: Sarif::SuppressionStatus::Rejected,
      guid: "abc-def",
      justification: "Not a real issue"
    )
    restored = Sarif::Suppression.from_json(s.to_json)
    restored.kind.should eq(Sarif::SuppressionKind::External)
    restored.status.should eq(Sarif::SuppressionStatus::Rejected)
    restored.guid.should eq("abc-def")
    restored.justification.should eq("Not a real issue")
  end
end
