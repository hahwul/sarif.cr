require "../spec_helper"

describe Sarif::StackFrame do
  it "creates with location" do
    sf = Sarif::StackFrame.new(
      location: Sarif::Location.new(
        physical_location: Sarif::PhysicalLocation.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
          region: Sarif::Region.new(start_line: 42)
        )
      )
    )
    sf.location.not_nil!.physical_location.not_nil!.region.not_nil!.start_line.should eq(42)
  end

  it "creates with module name and thread id" do
    sf = Sarif::StackFrame.new(module_name: "mylib.so", thread_id: 1234)
    sf.module_name.should eq("mylib.so")
    sf.thread_id.should eq(1234)
  end

  it "creates with parameters" do
    sf = Sarif::StackFrame.new(parameters: ["arg1", "arg2"])
    sf.parameters.not_nil!.should eq(["arg1", "arg2"])
  end

  it "defaults all fields to nil" do
    sf = Sarif::StackFrame.new
    sf.location.should be_nil
    sf.module_name.should be_nil
    sf.thread_id.should be_nil
    sf.parameters.should be_nil
    sf.properties.should be_nil
  end

  it "serializes with camelCase keys" do
    sf = Sarif::StackFrame.new(module_name: "lib", thread_id: 5)
    json = sf.to_json
    parsed = JSON.parse(json)
    parsed["module"].as_s.should eq("lib")
    parsed["threadId"].as_i.should eq(5)
  end

  it "round-trips through JSON" do
    sf = Sarif::StackFrame.new(
      module_name: "mylib",
      thread_id: 99,
      parameters: ["x", "y"]
    )
    json = sf.to_json
    restored = Sarif::StackFrame.from_json(json)
    restored.module_name.should eq("mylib")
    restored.thread_id.should eq(99)
    restored.parameters.not_nil!.should eq(["x", "y"])
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["info"] = JSON::Any.new("data")
    sf = Sarif::StackFrame.new(properties: bag)
    json = sf.to_json
    restored = Sarif::StackFrame.from_json(json)
    restored.properties.not_nil!["info"].as_s.should eq("data")
  end
end
