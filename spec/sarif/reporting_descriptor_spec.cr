require "../spec_helper"

describe Sarif::ReportingDescriptor do
  it "creates with required id" do
    rd = Sarif::ReportingDescriptor.new(id: "RULE001")
    rd.id.should eq("RULE001")
  end

  it "creates with all optional fields" do
    rd = Sarif::ReportingDescriptor.new(
      id: "RULE001",
      name: "NoUnusedVars",
      guid: "12345678-1234-1234-1234-123456789abc",
      short_description: Sarif::MultiformatMessageString.new(text: "Short desc"),
      full_description: Sarif::MultiformatMessageString.new(text: "Full description"),
      help_uri: "https://example.com/rules/001",
      help: Sarif::MultiformatMessageString.new(text: "Help text"),
      deprecated_ids: ["OLD001"],
      deprecated_names: ["OldRule"],
      deprecated_guids: ["00000000-0000-0000-0000-000000000000"]
    )
    rd.name.should eq("NoUnusedVars")
    rd.guid.should eq("12345678-1234-1234-1234-123456789abc")
    rd.short_description.not_nil!.text.should eq("Short desc")
    rd.full_description.not_nil!.text.should eq("Full description")
    rd.help_uri.should eq("https://example.com/rules/001")
    rd.deprecated_ids.not_nil!.should eq(["OLD001"])
    rd.deprecated_names.not_nil!.should eq(["OldRule"])
  end

  it "defaults optional fields to nil" do
    rd = Sarif::ReportingDescriptor.new(id: "R1")
    rd.name.should be_nil
    rd.guid.should be_nil
    rd.short_description.should be_nil
    rd.full_description.should be_nil
    rd.message_strings.should be_nil
    rd.default_configuration.should be_nil
    rd.help_uri.should be_nil
    rd.help.should be_nil
    rd.relationships.should be_nil
    rd.deprecated_ids.should be_nil
    rd.deprecated_names.should be_nil
    rd.deprecated_guids.should be_nil
    rd.properties.should be_nil
  end

  it "serializes with camelCase keys" do
    rd = Sarif::ReportingDescriptor.new(
      id: "R1",
      short_description: Sarif::MultiformatMessageString.new(text: "desc"),
      help_uri: "https://example.com",
      deprecated_ids: ["OLD1"]
    )
    json = rd.to_json
    parsed = JSON.parse(json)
    parsed["id"].as_s.should eq("R1")
    parsed["shortDescription"]["text"].as_s.should eq("desc")
    parsed["helpUri"].as_s.should eq("https://example.com")
    parsed["deprecatedIds"][0].as_s.should eq("OLD1")
  end

  it "round-trips through JSON" do
    rd = Sarif::ReportingDescriptor.new(
      id: "RULE001",
      name: "TestRule",
      guid: "abcdef01-2345-6789-abcd-ef0123456789",
      help_uri: "https://example.com/help"
    )
    json = rd.to_json
    restored = Sarif::ReportingDescriptor.from_json(json)
    restored.id.should eq("RULE001")
    restored.name.should eq("TestRule")
    restored.guid.should eq("abcdef01-2345-6789-abcd-ef0123456789")
    restored.help_uri.should eq("https://example.com/help")
  end

  it "supports message strings" do
    rd = Sarif::ReportingDescriptor.new(
      id: "R1",
      message_strings: {
        "default" => Sarif::MultiformatMessageString.new(text: "Variable '{0}' is unused"),
      }
    )
    json = rd.to_json
    parsed = JSON.parse(json)
    parsed["messageStrings"]["default"]["text"].as_s.should eq("Variable '{0}' is unused")
  end

  it "supports default configuration" do
    rd = Sarif::ReportingDescriptor.new(
      id: "R1",
      default_configuration: Sarif::ReportingConfiguration.new(
        level: Sarif::Level::Error,
        rank: 80.0
      )
    )
    json = rd.to_json
    restored = Sarif::ReportingDescriptor.from_json(json)
    restored.default_configuration.not_nil!.level.should eq(Sarif::Level::Error)
    restored.default_configuration.not_nil!.rank.should eq(80.0)
  end

  describe "#valid?" do
    it "returns true for valid descriptor" do
      Sarif::ReportingDescriptor.new(id: "R1").valid?.should be_true
    end

    it "returns false for empty id" do
      Sarif::ReportingDescriptor.new(id: "").valid?.should be_false
    end

    it "returns false for invalid guid" do
      Sarif::ReportingDescriptor.new(id: "R1", guid: "not-a-guid").valid?.should be_false
    end

    it "returns true for valid guid" do
      Sarif::ReportingDescriptor.new(
        id: "R1",
        guid: "12345678-1234-1234-1234-123456789abc"
      ).valid?.should be_true
    end

    it "returns false for rank > 100 in default configuration" do
      Sarif::ReportingDescriptor.new(
        id: "R1",
        default_configuration: Sarif::ReportingConfiguration.new(rank: 101.0)
      ).valid?.should be_false
    end

    it "returns false for negative rank in default configuration" do
      Sarif::ReportingDescriptor.new(
        id: "R1",
        default_configuration: Sarif::ReportingConfiguration.new(rank: -1.0)
      ).valid?.should be_false
    end
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["severity"] = JSON::Any.new("high")
    rd = Sarif::ReportingDescriptor.new(id: "R1", properties: bag)
    json = rd.to_json
    restored = Sarif::ReportingDescriptor.from_json(json)
    restored.properties.not_nil!["severity"].as_s.should eq("high")
  end
end
