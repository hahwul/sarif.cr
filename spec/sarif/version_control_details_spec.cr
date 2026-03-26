require "../spec_helper"

describe Sarif::VersionControlDetails do
  it "creates with repository URI" do
    vcd = Sarif::VersionControlDetails.new(repository_uri: "https://github.com/user/repo")
    vcd.repository_uri.should eq("https://github.com/user/repo")
    vcd.revision_id.should be_nil
    vcd.branch.should be_nil
  end

  it "creates with full details" do
    vcd = Sarif::VersionControlDetails.new(
      repository_uri: "https://github.com/user/repo",
      revision_id: "abc123def",
      branch: "main",
      revision_tag: "v1.0.0",
      as_of_time_utc: "2024-01-01T00:00:00Z",
      mapped_to: Sarif::ArtifactLocation.new(uri: "file:///home/user/repo")
    )
    vcd.revision_id.should eq("abc123def")
    vcd.branch.should eq("main")
    vcd.revision_tag.should eq("v1.0.0")
  end

  it "serializes with camelCase keys" do
    vcd = Sarif::VersionControlDetails.new(
      repository_uri: "https://github.com/test/repo",
      revision_id: "sha1",
      revision_tag: "v2.0",
      as_of_time_utc: "2024-06-01T00:00:00Z"
    )
    json = vcd.to_json
    parsed = JSON.parse(json)
    parsed["repositoryUri"].as_s.should eq("https://github.com/test/repo")
    parsed["revisionId"].as_s.should eq("sha1")
    parsed["revisionTag"].as_s.should eq("v2.0")
    parsed["asOfTimeUtc"].as_s.should eq("2024-06-01T00:00:00Z")
  end

  it "round-trips through JSON" do
    vcd = Sarif::VersionControlDetails.new(
      repository_uri: "https://github.com/user/repo",
      revision_id: "deadbeef",
      branch: "develop",
      mapped_to: Sarif::ArtifactLocation.new(uri: "/src", uri_base_id: "%SRCROOT%")
    )
    restored = Sarif::VersionControlDetails.from_json(vcd.to_json)
    restored.repository_uri.should eq("https://github.com/user/repo")
    restored.revision_id.should eq("deadbeef")
    restored.branch.should eq("develop")
    restored.mapped_to.not_nil!.uri.should eq("/src")
  end
end
