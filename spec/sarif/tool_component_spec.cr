require "../spec_helper"

describe Sarif::ToolComponent do
  it "creates with name only" do
    tc = Sarif::ToolComponent.new(name: "MyTool")
    tc.name.should eq("MyTool")
    tc.version.should be_nil
    tc.rules.should be_nil
  end

  it "creates with full metadata" do
    tc = Sarif::ToolComponent.new(
      name: "Analyzer",
      version: "1.2.3",
      semantic_version: "1.2.3-beta",
      guid: "550e8400-e29b-41d4-a716-446655440000",
      organization: "ACME",
      product: "Security Suite",
      full_name: "ACME Analyzer 1.2.3",
      language: "en-US",
      information_uri: "https://example.com/analyzer"
    )
    tc.version.should eq("1.2.3")
    tc.semantic_version.should eq("1.2.3-beta")
    tc.guid.should eq("550e8400-e29b-41d4-a716-446655440000")
    tc.organization.should eq("ACME")
    tc.full_name.should eq("ACME Analyzer 1.2.3")
  end

  it "serializes with camelCase keys" do
    tc = Sarif::ToolComponent.new(
      name: "Tool",
      semantic_version: "2.0.0",
      information_uri: "https://example.com",
      download_uri: "https://example.com/download",
      full_name: "Full Tool Name",
      product_suite: "Suite",
      is_comprehensive: true
    )
    json = tc.to_json
    parsed = JSON.parse(json)
    parsed["semanticVersion"].as_s.should eq("2.0.0")
    parsed["informationUri"].as_s.should eq("https://example.com")
    parsed["downloadUri"].as_s.should eq("https://example.com/download")
    parsed["fullName"].as_s.should eq("Full Tool Name")
    parsed["productSuite"].as_s.should eq("Suite")
    parsed["isComprehensive"].as_bool.should be_true
  end

  it "supports rules" do
    tc = Sarif::ToolComponent.new(
      name: "Linter",
      rules: [
        Sarif::ReportingDescriptor.new(id: "R001", name: "NoUnused"),
        Sarif::ReportingDescriptor.new(id: "R002", name: "NoShadow"),
      ]
    )
    tc.rules.not_nil!.size.should eq(2)
    tc.rules.not_nil![0].id.should eq("R001")
    tc.rules.not_nil![1].name.should eq("NoShadow")
  end

  it "supports notifications and taxa" do
    tc = Sarif::ToolComponent.new(
      name: "Tool",
      notifications: [Sarif::ReportingDescriptor.new(id: "N001")],
      taxa: [Sarif::ReportingDescriptor.new(id: "CWE-79", name: "XSS")]
    )
    tc.notifications.not_nil![0].id.should eq("N001")
    tc.taxa.not_nil![0].name.should eq("XSS")
  end

  it "supports descriptions" do
    tc = Sarif::ToolComponent.new(
      name: "Tool",
      short_description: Sarif::MultiformatMessageString.new(text: "Short desc"),
      full_description: Sarif::MultiformatMessageString.new(text: "Full description", markdown: "**Full** description")
    )
    json = tc.to_json
    parsed = JSON.parse(json)
    parsed["shortDescription"]["text"].as_s.should eq("Short desc")
    parsed["fullDescription"]["markdown"].as_s.should eq("**Full** description")
  end

  it "supports global message strings" do
    tc = Sarif::ToolComponent.new(
      name: "Tool",
      global_message_strings: {
        "notFound" => Sarif::MultiformatMessageString.new(text: "Resource not found: {0}"),
      }
    )
    json = tc.to_json
    parsed = JSON.parse(json)
    parsed["globalMessageStrings"]["notFound"]["text"].as_s.should eq("Resource not found: {0}")
  end

  it "round-trips through JSON" do
    tc = Sarif::ToolComponent.new(
      name: "RoundTripper",
      version: "3.0",
      guid: "abc-123",
      organization: "Test Org",
      information_uri: "https://example.com",
      rules: [Sarif::ReportingDescriptor.new(id: "RULE1")],
      language: "en-US"
    )
    restored = Sarif::ToolComponent.from_json(tc.to_json)
    restored.name.should eq("RoundTripper")
    restored.version.should eq("3.0")
    restored.guid.should eq("abc-123")
    restored.organization.should eq("Test Org")
    restored.rules.not_nil![0].id.should eq("RULE1")
  end
end
