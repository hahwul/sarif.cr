require "../spec_helper"

describe Sarif::PhysicalLocation do
  it "creates with defaults" do
    pl = Sarif::PhysicalLocation.new
    pl.artifact_location.should be_nil
    pl.region.should be_nil
    pl.context_region.should be_nil
    pl.address.should be_nil
  end

  it "creates with artifact location and region" do
    pl = Sarif::PhysicalLocation.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
      region: Sarif::Region.new(start_line: 10, start_column: 5, end_line: 10, end_column: 20)
    )
    pl.artifact_location.not_nil!.uri.should eq("src/main.cr")
    pl.region.not_nil!.start_line.should eq(10)
    pl.region.not_nil!.end_column.should eq(20)
  end

  it "supports context region" do
    pl = Sarif::PhysicalLocation.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
      region: Sarif::Region.new(start_line: 10),
      context_region: Sarif::Region.new(start_line: 8, end_line: 12,
        snippet: Sarif::ArtifactContent.new(text: "surrounding context"))
    )
    pl.context_region.not_nil!.start_line.should eq(8)
    pl.context_region.not_nil!.snippet.not_nil!.text.should eq("surrounding context")
  end

  it "serializes with camelCase keys" do
    pl = Sarif::PhysicalLocation.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "f.cr"),
      context_region: Sarif::Region.new(start_line: 1)
    )
    json = pl.to_json
    parsed = JSON.parse(json)
    parsed["artifactLocation"]["uri"].as_s.should eq("f.cr")
    parsed["contextRegion"]["startLine"].as_i.should eq(1)
  end

  it "round-trips through JSON" do
    pl = Sarif::PhysicalLocation.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "test.cr", uri_base_id: "%SRCROOT%"),
      region: Sarif::Region.new(start_line: 5, start_column: 3),
      context_region: Sarif::Region.new(start_line: 3, end_line: 7)
    )
    restored = Sarif::PhysicalLocation.from_json(pl.to_json)
    restored.artifact_location.not_nil!.uri.should eq("test.cr")
    restored.artifact_location.not_nil!.uri_base_id.should eq("%SRCROOT%")
    restored.region.not_nil!.start_line.should eq(5)
    restored.context_region.not_nil!.start_line.should eq(3)
  end

  it "supports address" do
    pl = Sarif::PhysicalLocation.new(
      address: Sarif::Address.new(absolute_address: 1024)
    )
    pl.address.not_nil!.absolute_address.should eq(1024)
  end

  describe "#valid?" do
    it "returns true with artifact location" do
      pl = Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr")
      )
      pl.valid?.should be_true
    end

    it "returns true with address" do
      pl = Sarif::PhysicalLocation.new(
        address: Sarif::Address.new(absolute_address: 0)
      )
      pl.valid?.should be_true
    end

    it "returns false without artifact location or address" do
      pl = Sarif::PhysicalLocation.new
      pl.valid?.should be_false
    end

    it "returns false when region is invalid" do
      pl = Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
        region: Sarif::Region.new(start_line: 0)
      )
      pl.valid?.should be_false
    end

    it "returns false when context region is invalid" do
      pl = Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
        context_region: Sarif::Region.new(start_line: 10, end_line: 5)
      )
      pl.valid?.should be_false
    end
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["key"] = JSON::Any.new("value")
    pl = Sarif::PhysicalLocation.new(
      artifact_location: Sarif::ArtifactLocation.new(uri: "f.cr"),
      properties: bag
    )
    json = pl.to_json
    restored = Sarif::PhysicalLocation.from_json(json)
    restored.properties.not_nil!["key"].as_s.should eq("value")
  end
end

