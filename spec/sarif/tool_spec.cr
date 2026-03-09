require "../spec_helper"

describe Sarif::Tool do
  it "creates with driver" do
    tool = Sarif::Tool.new(
      driver: Sarif::ToolComponent.new(name: "MyTool", version: "1.0.0")
    )
    tool.driver.name.should eq("MyTool")
    tool.driver.version.should eq("1.0.0")
    tool.extensions.should be_nil
  end

  it "serializes with rules" do
    tool = Sarif::Tool.new(
      driver: Sarif::ToolComponent.new(
        name: "Linter",
        version: "2.0",
        rules: [
          Sarif::ReportingDescriptor.new(
            id: "R001", name: "NoUnused",
            short_description: Sarif::MultiformatMessageString.new(text: "No unused variables"),
            default_configuration: Sarif::ReportingConfiguration.new(level: Sarif::Level::Warning)
          ),
        ]
      )
    )
    json = tool.to_json
    parsed = JSON.parse(json)
    parsed["driver"]["name"].as_s.should eq("Linter")
    parsed["driver"]["rules"][0]["id"].as_s.should eq("R001")
    parsed["driver"]["rules"][0]["shortDescription"]["text"].as_s.should eq("No unused variables")
    parsed["driver"]["rules"][0]["defaultConfiguration"]["level"].as_s.should eq("warning")
  end

  it "supports extensions" do
    tool = Sarif::Tool.new(
      driver: Sarif::ToolComponent.new(name: "MainTool"),
      extensions: [
        Sarif::ToolComponent.new(name: "SecurityPlugin", version: "0.5.0"),
      ]
    )
    json = tool.to_json
    parsed = JSON.parse(json)
    parsed["extensions"][0]["name"].as_s.should eq("SecurityPlugin")
  end

  it "round-trips through JSON" do
    tool = Sarif::Tool.new(
      driver: Sarif::ToolComponent.new(
        name: "Analyzer", version: "3.0", guid: "abc-123",
        information_uri: "https://example.com",
        rules: [
          Sarif::ReportingDescriptor.new(id: "RULE1", help_uri: "https://example.com/rule1"),
        ]
      )
    )
    restored = Sarif::Tool.from_json(tool.to_json)
    restored.driver.name.should eq("Analyzer")
    restored.driver.version.should eq("3.0")
    restored.driver.guid.should eq("abc-123")
    restored.driver.information_uri.should eq("https://example.com")
    restored.driver.rules.not_nil![0].id.should eq("RULE1")
  end
end

describe Sarif::ReportingDescriptor do
  it "serializes messageStrings" do
    rd = Sarif::ReportingDescriptor.new(
      id: "R1",
      message_strings: {
        "default" => Sarif::MultiformatMessageString.new(text: "Error: {0}"),
      }
    )
    json = rd.to_json
    parsed = JSON.parse(json)
    parsed["messageStrings"]["default"]["text"].as_s.should eq("Error: {0}")
  end

  it "supports relationships" do
    rd = Sarif::ReportingDescriptor.new(
      id: "R1",
      relationships: [
        Sarif::ReportingDescriptorRelationship.new(
          target: Sarif::ReportingDescriptorReference.new(id: "CWE-79", guid: "guid123"),
          kinds: ["superset"]
        ),
      ]
    )
    json = rd.to_json
    restored = Sarif::ReportingDescriptor.from_json(json)
    restored.relationships.not_nil![0].target.id.should eq("CWE-79")
    restored.relationships.not_nil![0].kinds.should eq(["superset"])
  end
end
