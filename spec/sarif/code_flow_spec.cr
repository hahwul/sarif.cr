require "../spec_helper"

describe Sarif::CodeFlow do
  it "creates with thread flows" do
    cf = Sarif::CodeFlow.new(
      thread_flows: [
        Sarif::ThreadFlow.new(
          locations: [
            Sarif::ThreadFlowLocation.new(index: 0),
          ]
        ),
      ]
    )
    cf.thread_flows.size.should eq(1)
    cf.message.should be_nil
  end

  it "supports message" do
    cf = Sarif::CodeFlow.new(
      message: Sarif::Message.new(text: "Taint propagation"),
      thread_flows: [
        Sarif::ThreadFlow.new(locations: [Sarif::ThreadFlowLocation.new]),
      ]
    )
    cf.message.not_nil!.text.should eq("Taint propagation")
  end

  it "serializes with camelCase keys" do
    cf = Sarif::CodeFlow.new(
      thread_flows: [
        Sarif::ThreadFlow.new(locations: [Sarif::ThreadFlowLocation.new(nesting_level: 0)]),
      ]
    )
    json = cf.to_json
    parsed = JSON.parse(json)
    parsed["threadFlows"].as_a.size.should eq(1)
  end

  it "round-trips through JSON" do
    cf = Sarif::CodeFlow.new(
      message: Sarif::Message.new(text: "data flow"),
      thread_flows: [
        Sarif::ThreadFlow.new(
          id: "flow1",
          locations: [
            Sarif::ThreadFlowLocation.new(
              index: 0,
              location: Sarif::Location.new(
                physical_location: Sarif::PhysicalLocation.new(
                  artifact_location: Sarif::ArtifactLocation.new(uri: "a.cr"),
                  region: Sarif::Region.new(start_line: 1)
                )
              )
            ),
          ]
        ),
      ]
    )
    restored = Sarif::CodeFlow.from_json(cf.to_json)
    restored.message.not_nil!.text.should eq("data flow")
    restored.thread_flows[0].id.should eq("flow1")
    restored.thread_flows[0].locations[0].index.should eq(0)
  end
end

describe Sarif::ThreadFlow do
  it "creates with locations" do
    tf = Sarif::ThreadFlow.new(
      locations: [Sarif::ThreadFlowLocation.new]
    )
    tf.locations.size.should eq(1)
    tf.id.should be_nil
    tf.message.should be_nil
  end

  it "supports initial and immutable state" do
    tf = Sarif::ThreadFlow.new(
      locations: [Sarif::ThreadFlowLocation.new],
      initial_state: {"x" => Sarif::MultiformatMessageString.new(text: "0")},
      immutable_state: {"const" => Sarif::MultiformatMessageString.new(text: "42")}
    )
    json = tf.to_json
    parsed = JSON.parse(json)
    parsed["initialState"]["x"]["text"].as_s.should eq("0")
    parsed["immutableState"]["const"]["text"].as_s.should eq("42")
  end

  it "round-trips through JSON" do
    tf = Sarif::ThreadFlow.new(
      id: "thread1",
      message: Sarif::Message.new(text: "main thread"),
      locations: [
        Sarif::ThreadFlowLocation.new(index: 0, nesting_level: 0),
        Sarif::ThreadFlowLocation.new(index: 1, nesting_level: 1),
      ]
    )
    restored = Sarif::ThreadFlow.from_json(tf.to_json)
    restored.id.should eq("thread1")
    restored.message.not_nil!.text.should eq("main thread")
    restored.locations.size.should eq(2)
  end
end

describe Sarif::ThreadFlowLocation do
  it "creates with defaults" do
    tfl = Sarif::ThreadFlowLocation.new
    tfl.index.should be_nil
    tfl.location.should be_nil
    tfl.kinds.should be_nil
    tfl.nesting_level.should be_nil
    tfl.importance.should be_nil
  end

  it "creates with full details" do
    tfl = Sarif::ThreadFlowLocation.new(
      index: 0,
      nesting_level: 1,
      execution_order: 2,
      importance: Sarif::Importance::Essential,
      kinds: ["call"],
      module_name: "MyModule"
    )
    tfl.index.should eq(0)
    tfl.nesting_level.should eq(1)
    tfl.execution_order.should eq(2)
    tfl.importance.should eq(Sarif::Importance::Essential)
    tfl.kinds.should eq(["call"])
    tfl.module_name.should eq("MyModule")
  end

  it "serializes with camelCase keys" do
    tfl = Sarif::ThreadFlowLocation.new(
      nesting_level: 2,
      execution_order: 5,
      execution_time_utc: "2024-01-01T00:00:00Z",
      module_name: "Mod"
    )
    json = tfl.to_json
    parsed = JSON.parse(json)
    parsed["nestingLevel"].as_i.should eq(2)
    parsed["executionOrder"].as_i.should eq(5)
    parsed["executionTimeUtc"].as_s.should eq("2024-01-01T00:00:00Z")
    parsed["module"].as_s.should eq("Mod")
  end

  it "supports web request/response" do
    tfl = Sarif::ThreadFlowLocation.new(
      web_request: Sarif::WebRequest.new(
        method: "GET",
        target: "/api/data",
        protocol: "HTTP",
        version: "1.1"
      ),
      web_response: Sarif::WebResponse.new(
        status_code: 200,
        reason_phrase: "OK"
      )
    )
    json = tfl.to_json
    parsed = JSON.parse(json)
    parsed["webRequest"]["method"].as_s.should eq("GET")
    parsed["webResponse"]["statusCode"].as_i.should eq(200)
  end

  it "round-trips through JSON" do
    tfl = Sarif::ThreadFlowLocation.new(
      index: 3,
      nesting_level: 1,
      importance: Sarif::Importance::Important,
      location: Sarif::Location.new(
        physical_location: Sarif::PhysicalLocation.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "file.cr"),
          region: Sarif::Region.new(start_line: 10)
        )
      )
    )
    restored = Sarif::ThreadFlowLocation.from_json(tfl.to_json)
    restored.index.should eq(3)
    restored.nesting_level.should eq(1)
    restored.importance.should eq(Sarif::Importance::Important)
    restored.location.not_nil!.physical_location.not_nil!.artifact_location.not_nil!.uri.should eq("file.cr")
  end
end
