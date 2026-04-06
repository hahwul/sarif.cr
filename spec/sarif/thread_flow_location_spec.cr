require "../spec_helper"

describe Sarif::ThreadFlowLocation do
  it "creates with basic fields" do
    tfl = Sarif::ThreadFlowLocation.new(
      location: Sarif::Location.new(
        physical_location: Sarif::PhysicalLocation.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
          region: Sarif::Region.new(start_line: 10)
        )
      ),
      importance: Sarif::Importance::Essential
    )
    tfl.location.not_nil!.physical_location.not_nil!.region.not_nil!.start_line.should eq(10)
    tfl.importance.should eq(Sarif::Importance::Essential)
  end

  it "creates with index and nesting level" do
    tfl = Sarif::ThreadFlowLocation.new(index: 0, nesting_level: 2, execution_order: 1)
    tfl.index.should eq(0)
    tfl.nesting_level.should eq(2)
    tfl.execution_order.should eq(1)
  end

  it "defaults all fields to nil" do
    tfl = Sarif::ThreadFlowLocation.new
    tfl.index.should be_nil
    tfl.location.should be_nil
    tfl.stack.should be_nil
    tfl.kinds.should be_nil
    tfl.taxa.should be_nil
    tfl.module_name.should be_nil
    tfl.state.should be_nil
    tfl.nesting_level.should be_nil
    tfl.execution_order.should be_nil
    tfl.execution_time_utc.should be_nil
    tfl.importance.should be_nil
    tfl.web_request.should be_nil
    tfl.web_response.should be_nil
    tfl.properties.should be_nil
  end

  it "supports kinds and module name" do
    tfl = Sarif::ThreadFlowLocation.new(
      kinds: ["call", "branch"],
      module_name: "mylib.so"
    )
    tfl.kinds.not_nil!.should eq(["call", "branch"])
    tfl.module_name.should eq("mylib.so")
  end

  it "serializes with camelCase keys" do
    tfl = Sarif::ThreadFlowLocation.new(
      nesting_level: 1,
      execution_order: 3,
      execution_time_utc: "2024-01-01T00:00:00Z",
      module_name: "test"
    )
    json = tfl.to_json
    parsed = JSON.parse(json)
    parsed["nestingLevel"].as_i.should eq(1)
    parsed["executionOrder"].as_i.should eq(3)
    parsed["executionTimeUtc"].as_s.should eq("2024-01-01T00:00:00Z")
    parsed["module"].as_s.should eq("test")
  end

  it "round-trips through JSON" do
    tfl = Sarif::ThreadFlowLocation.new(
      index: 0,
      nesting_level: 1,
      importance: Sarif::Importance::Important,
      kinds: ["call"],
      module_name: "mod"
    )
    json = tfl.to_json
    restored = Sarif::ThreadFlowLocation.from_json(json)
    restored.index.should eq(0)
    restored.nesting_level.should eq(1)
    restored.importance.should eq(Sarif::Importance::Important)
    restored.kinds.not_nil!.should eq(["call"])
    restored.module_name.should eq("mod")
  end

  it "supports state map" do
    tfl = Sarif::ThreadFlowLocation.new(
      state: {
        "x" => Sarif::MultiformatMessageString.new(text: "value of x"),
      }
    )
    json = tfl.to_json
    parsed = JSON.parse(json)
    parsed["state"]["x"]["text"].as_s.should eq("value of x")
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["custom"] = JSON::Any.new("data")
    tfl = Sarif::ThreadFlowLocation.new(properties: bag)
    json = tfl.to_json
    restored = Sarif::ThreadFlowLocation.from_json(json)
    restored.properties.not_nil!["custom"].as_s.should eq("data")
  end
end
