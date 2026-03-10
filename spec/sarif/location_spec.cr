require "../spec_helper"

describe Sarif::Location do
  it "creates a location with physical location" do
    loc = Sarif::Location.new(
      physical_location: Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "src/main.cr"),
        region: Sarif::Region.new(start_line: 10, start_column: 5)
      )
    )
    loc.physical_location.not_nil!.artifact_location.not_nil!.uri.should eq("src/main.cr")
    loc.physical_location.not_nil!.region.not_nil!.start_line.should eq(10)
  end

  it "serializes with camelCase keys" do
    loc = Sarif::Location.new(
      id: 0,
      physical_location: Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
        region: Sarif::Region.new(start_line: 1, end_line: 5)
      )
    )
    json = loc.to_json
    parsed = JSON.parse(json)
    parsed["physicalLocation"]["artifactLocation"]["uri"].as_s.should eq("file.cr")
    parsed["physicalLocation"]["region"]["startLine"].as_i.should eq(1)
    parsed["physicalLocation"]["region"]["endLine"].as_i.should eq(5)
  end

  it "round-trips through JSON" do
    loc = Sarif::Location.new(
      id: 1,
      physical_location: Sarif::PhysicalLocation.new(
        artifact_location: Sarif::ArtifactLocation.new(uri: "test.cr", uri_base_id: "%SRCROOT%"),
        region: Sarif::Region.new(start_line: 10, start_column: 3, end_line: 12, end_column: 20)
      ),
      message: Sarif::Message.new(text: "relevant location")
    )
    json = loc.to_json
    restored = Sarif::Location.from_json(json)
    restored.id.should eq(1)
    restored.physical_location.not_nil!.artifact_location.not_nil!.uri.should eq("test.cr")
    restored.physical_location.not_nil!.artifact_location.not_nil!.uri_base_id.should eq("%SRCROOT%")
    restored.message.not_nil!.text.should eq("relevant location")
  end

  it "supports logical locations" do
    loc = Sarif::Location.new(
      logical_locations: [
        Sarif::LogicalLocation.new(name: "MyClass", kind: "type",
          fully_qualified_name: "MyModule::MyClass"),
      ]
    )
    json = loc.to_json
    parsed = JSON.parse(json)
    parsed["logicalLocations"][0]["fullyQualifiedName"].as_s.should eq("MyModule::MyClass")
  end

  it "supports location relationships" do
    loc = Sarif::Location.new(
      id: 0,
      relationships: [
        Sarif::LocationRelationship.new(target: 1, kinds: ["isResultOf"]),
      ]
    )
    json = loc.to_json
    restored = Sarif::Location.from_json(json)
    restored.relationships.not_nil!.size.should eq(1)
    restored.relationships.not_nil![0].target.should eq(1)
    restored.relationships.not_nil![0].kinds.should eq(["isResultOf"])
  end
end

describe Sarif::Region do
  it "serializes byte offset/length" do
    region = Sarif::Region.new(byte_offset: 100, byte_length: 50)
    json = region.to_json
    parsed = JSON.parse(json)
    parsed["byteOffset"].as_i.should eq(100)
    parsed["byteLength"].as_i.should eq(50)
  end
end

describe Sarif::ArtifactLocation do
  it "serializes uriBaseId" do
    al = Sarif::ArtifactLocation.new(uri: "src/main.cr", uri_base_id: "%SRCROOT%")
    json = al.to_json
    parsed = JSON.parse(json)
    parsed["uriBaseId"].as_s.should eq("%SRCROOT%")
  end
end
