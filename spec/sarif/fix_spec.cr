require "../spec_helper"

describe Sarif::Fix do
  it "creates with artifact changes" do
    fix = Sarif::Fix.new(
      artifact_changes: [
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
          replacements: [
            Sarif::Replacement.new(
              deleted_region: Sarif::Region.new(start_line: 1, end_line: 1),
              inserted_content: Sarif::ArtifactContent.new(text: "fixed")
            ),
          ]
        ),
      ]
    )
    fix.artifact_changes.size.should eq(1)
    fix.description.should be_nil
  end

  it "supports description" do
    fix = Sarif::Fix.new(
      description: Sarif::Message.new(text: "Replace deprecated API call"),
      artifact_changes: [
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "f.cr"),
          replacements: [
            Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 5)),
          ]
        ),
      ]
    )
    fix.description.not_nil!.text.should eq("Replace deprecated API call")
  end

  it "serializes with camelCase keys" do
    fix = Sarif::Fix.new(
      artifact_changes: [
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
          replacements: [
            Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 1)),
          ]
        ),
      ]
    )
    json = fix.to_json
    parsed = JSON.parse(json)
    parsed["artifactChanges"].as_a.size.should eq(1)
    parsed["artifactChanges"][0]["artifactLocation"]["uri"].as_s.should eq("a.cr")
  end

  it "supports multiple artifact changes" do
    fix = Sarif::Fix.new(
      artifact_changes: [
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file1.cr"),
          replacements: [Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 1))]
        ),
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file2.cr"),
          replacements: [Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 10))]
        ),
      ]
    )
    fix.artifact_changes.size.should eq(2)
  end

  it "round-trips through JSON" do
    fix = Sarif::Fix.new(
      description: Sarif::Message.new(text: "Apply fix"),
      artifact_changes: [
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
          replacements: [
            Sarif::Replacement.new(
              deleted_region: Sarif::Region.new(start_line: 10, start_column: 1, end_line: 10, end_column: 20),
              inserted_content: Sarif::ArtifactContent.new(text: "new_code()")
            ),
          ]
        ),
      ]
    )
    restored = Sarif::Fix.from_json(fix.to_json)
    restored.description.not_nil!.text.should eq("Apply fix")
    restored.artifact_changes[0].artifact_location.uri.should eq("src/main.cr")
    restored.artifact_changes[0].replacements[0].inserted_content.not_nil!.text.should eq("new_code()")
  end
end
