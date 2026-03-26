require "../spec_helper"

describe Sarif::LogicalLocation do
  it "creates with defaults" do
    ll = Sarif::LogicalLocation.new
    ll.name.should be_nil
    ll.kind.should be_nil
  end

  it "creates with full details" do
    ll = Sarif::LogicalLocation.new(
      name: "process_data",
      fully_qualified_name: "MyApp::DataProcessor#process_data",
      decorated_name: "?process_data@@YAXHH@Z",
      kind: "function",
      parent_index: 0,
      index: 1
    )
    ll.name.should eq("process_data")
    ll.fully_qualified_name.should eq("MyApp::DataProcessor#process_data")
    ll.kind.should eq("function")
    ll.parent_index.should eq(0)
  end

  it "serializes with camelCase keys" do
    ll = Sarif::LogicalLocation.new(
      name: "MyClass",
      fully_qualified_name: "Ns::MyClass",
      decorated_name: "decorated",
      parent_index: 0
    )
    json = ll.to_json
    parsed = JSON.parse(json)
    parsed["fullyQualifiedName"].as_s.should eq("Ns::MyClass")
    parsed["decoratedName"].as_s.should eq("decorated")
    parsed["parentIndex"].as_i.should eq(0)
  end

  it "round-trips through JSON" do
    ll = Sarif::LogicalLocation.new(
      name: "main",
      fully_qualified_name: "App::Main#main",
      kind: "function",
      index: 0
    )
    restored = Sarif::LogicalLocation.from_json(ll.to_json)
    restored.name.should eq("main")
    restored.fully_qualified_name.should eq("App::Main#main")
    restored.kind.should eq("function")
  end
end
