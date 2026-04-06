require "../spec_helper"

describe Sarif::ArtifactLocation do
  it "creates with uri" do
    al = Sarif::ArtifactLocation.new(uri: "src/main.cr")
    al.uri.should eq("src/main.cr")
  end

  it "creates with uri and uri base id" do
    al = Sarif::ArtifactLocation.new(uri: "src/main.cr", uri_base_id: "%SRCROOT%")
    al.uri.should eq("src/main.cr")
    al.uri_base_id.should eq("%SRCROOT%")
  end

  it "creates with index" do
    al = Sarif::ArtifactLocation.new(uri: "file.cr", index: 0)
    al.index.should eq(0)
  end

  it "creates with description" do
    al = Sarif::ArtifactLocation.new(
      uri: "file.cr",
      description: Sarif::Message.new(text: "Source file")
    )
    al.description.not_nil!.text.should eq("Source file")
  end

  it "defaults all fields to nil" do
    al = Sarif::ArtifactLocation.new
    al.uri.should be_nil
    al.uri_base_id.should be_nil
    al.index.should be_nil
    al.description.should be_nil
    al.properties.should be_nil
  end

  it "serializes with camelCase keys" do
    al = Sarif::ArtifactLocation.new(uri: "file.cr", uri_base_id: "%SRCROOT%")
    json = al.to_json
    parsed = JSON.parse(json)
    parsed["uri"].as_s.should eq("file.cr")
    parsed["uriBaseId"].as_s.should eq("%SRCROOT%")
  end

  it "round-trips through JSON" do
    al = Sarif::ArtifactLocation.new(
      uri: "src/test.cr",
      uri_base_id: "%SRCROOT%",
      index: 3,
      description: Sarif::Message.new(text: "test file")
    )
    json = al.to_json
    restored = Sarif::ArtifactLocation.from_json(json)
    restored.uri.should eq("src/test.cr")
    restored.uri_base_id.should eq("%SRCROOT%")
    restored.index.should eq(3)
    restored.description.not_nil!.text.should eq("test file")
  end

  it "omits nil fields from JSON" do
    al = Sarif::ArtifactLocation.new(uri: "file.cr")
    json = al.to_json
    parsed = JSON.parse(json)
    parsed["uri"].as_s.should eq("file.cr")
    parsed["uriBaseId"]?.should be_nil
    parsed["index"]?.should be_nil
  end

  describe "#valid?" do
    it "returns true for valid artifact location" do
      Sarif::ArtifactLocation.new(uri: "file.cr").valid?.should be_true
    end

    it "returns true with no fields set" do
      Sarif::ArtifactLocation.new.valid?.should be_true
    end

    it "returns true with valid index" do
      Sarif::ArtifactLocation.new(uri: "file.cr", index: 0).valid?.should be_true
    end

    it "returns true with index of -1" do
      Sarif::ArtifactLocation.new(index: -1).valid?.should be_true
    end

    it "returns false with index < -1" do
      Sarif::ArtifactLocation.new(index: -2).valid?.should be_false
    end
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["custom"] = JSON::Any.new("data")
    al = Sarif::ArtifactLocation.new(uri: "file.cr", properties: bag)
    json = al.to_json
    restored = Sarif::ArtifactLocation.from_json(json)
    restored.properties.not_nil!["custom"].as_s.should eq("data")
  end
end
