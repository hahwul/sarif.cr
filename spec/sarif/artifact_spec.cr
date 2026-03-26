require "../spec_helper"

describe Sarif::Artifact do
  it "creates with defaults" do
    artifact = Sarif::Artifact.new
    artifact.location.should be_nil
    artifact.contents.should be_nil
    artifact.roles.should be_nil
    artifact.hashes.should be_nil
    artifact.length.should be_nil
    artifact.mime_type.should be_nil
    artifact.encoding.should be_nil
    artifact.source_language.should be_nil
    artifact.parent_index.should be_nil
    artifact.offset.should be_nil
    artifact.description.should be_nil
    artifact.last_modified_time_utc.should be_nil
    artifact.properties.should be_nil
  end

  it "creates with location and mime type" do
    artifact = Sarif::Artifact.new(
      location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
      mime_type: "text/x-crystal",
      source_language: "crystal"
    )
    artifact.location.not_nil!.uri.should eq("src/main.cr")
    artifact.mime_type.should eq("text/x-crystal")
    artifact.source_language.should eq("crystal")
  end

  it "serializes with camelCase keys" do
    artifact = Sarif::Artifact.new(
      location: Sarif::ArtifactLocation.new(uri: "file.cr"),
      mime_type: "text/plain",
      source_language: "crystal",
      parent_index: 0,
      last_modified_time_utc: "2024-01-01T00:00:00Z"
    )
    json = artifact.to_json
    parsed = JSON.parse(json)
    parsed["mimeType"].as_s.should eq("text/plain")
    parsed["sourceLanguage"].as_s.should eq("crystal")
    parsed["parentIndex"].as_i.should eq(0)
    parsed["lastModifiedTimeUtc"].as_s.should eq("2024-01-01T00:00:00Z")
  end

  it "supports hashes" do
    artifact = Sarif::Artifact.new(
      location: Sarif::ArtifactLocation.new(uri: "file.cr"),
      hashes: {"sha-256" => "abc123", "md5" => "def456"}
    )
    json = artifact.to_json
    parsed = JSON.parse(json)
    parsed["hashes"]["sha-256"].as_s.should eq("abc123")
    parsed["hashes"]["md5"].as_s.should eq("def456")
  end

  it "supports roles" do
    artifact = Sarif::Artifact.new(
      roles: [Sarif::ArtifactRole::AnalysisTarget, Sarif::ArtifactRole::ResultFile]
    )
    json = artifact.to_json
    parsed = JSON.parse(json)
    parsed["roles"][0].as_s.should eq("analysisTarget")
    parsed["roles"][1].as_s.should eq("resultFile")
  end

  it "supports contents" do
    artifact = Sarif::Artifact.new(
      contents: Sarif::ArtifactContent.new(text: "puts \"hello\"")
    )
    artifact.contents.not_nil!.text.should eq("puts \"hello\"")
  end

  it "round-trips through JSON" do
    artifact = Sarif::Artifact.new(
      location: Sarif::ArtifactLocation.new(uri: "src/app.cr", uri_base_id: "%SRCROOT%"),
      mime_type: "text/x-crystal",
      length: 1024_i64,
      encoding: "UTF-8",
      hashes: {"sha-256" => "deadbeef"},
      roles: [Sarif::ArtifactRole::AnalysisTarget]
    )
    restored = Sarif::Artifact.from_json(artifact.to_json)
    restored.location.not_nil!.uri.should eq("src/app.cr")
    restored.location.not_nil!.uri_base_id.should eq("%SRCROOT%")
    restored.mime_type.should eq("text/x-crystal")
    restored.length.should eq(1024_i64)
    restored.encoding.should eq("UTF-8")
    restored.hashes.not_nil!["sha-256"].should eq("deadbeef")
    restored.roles.not_nil![0].should eq(Sarif::ArtifactRole::AnalysisTarget)
  end
end

describe Sarif::ArtifactContent do
  it "creates with text" do
    content = Sarif::ArtifactContent.new(text: "hello world")
    content.text.should eq("hello world")
    content.binary.should be_nil
  end

  it "creates with binary" do
    content = Sarif::ArtifactContent.new(binary: "aGVsbG8=")
    content.binary.should eq("aGVsbG8=")
  end

  it "supports rendered content" do
    content = Sarif::ArtifactContent.new(
      text: "hello",
      rendered: Sarif::MultiformatMessageString.new(text: "**hello**", markdown: "**hello**")
    )
    content.rendered.not_nil!.markdown.should eq("**hello**")
  end

  it "round-trips through JSON" do
    content = Sarif::ArtifactContent.new(text: "code", binary: "Y29kZQ==")
    restored = Sarif::ArtifactContent.from_json(content.to_json)
    restored.text.should eq("code")
    restored.binary.should eq("Y29kZQ==")
  end
end

describe Sarif::ArtifactChange do
  it "creates with location and replacements" do
    change = Sarif::ArtifactChange.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
      replacements: [
        Sarif::Replacement.new(
          deleted_region: Sarif::Region.new(start_line: 1, end_line: 1),
          inserted_content: Sarif::ArtifactContent.new(text: "new_code")
        ),
      ]
    )
    change.artifact_location.uri.should eq("file.cr")
    change.replacements.size.should eq(1)
  end

  it "serializes with camelCase keys" do
    change = Sarif::ArtifactChange.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "f.cr"),
      replacements: [
        Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 1)),
      ]
    )
    json = change.to_json
    parsed = JSON.parse(json)
    parsed["artifactLocation"]["uri"].as_s.should eq("f.cr")
    parsed["replacements"].as_a.size.should eq(1)
  end

  it "round-trips through JSON" do
    change = Sarif::ArtifactChange.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "test.cr"),
      replacements: [
        Sarif::Replacement.new(
          deleted_region: Sarif::Region.new(start_line: 5, start_column: 1, end_line: 5, end_column: 10),
          inserted_content: Sarif::ArtifactContent.new(text: "replaced")
        ),
      ]
    )
    restored = Sarif::ArtifactChange.from_json(change.to_json)
    restored.artifact_location.uri.should eq("test.cr")
    restored.replacements[0].inserted_content.not_nil!.text.should eq("replaced")
  end
end
