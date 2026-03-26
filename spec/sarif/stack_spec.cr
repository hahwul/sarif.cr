require "../spec_helper"

describe Sarif::Stack do
  it "creates with frames" do
    stack = Sarif::Stack.new(
      frames: [Sarif::StackFrame.new]
    )
    stack.frames.size.should eq(1)
    stack.message.should be_nil
  end

  it "supports message" do
    stack = Sarif::Stack.new(
      message: Sarif::Message.new(text: "Call stack at crash"),
      frames: [Sarif::StackFrame.new]
    )
    stack.message.not_nil!.text.should eq("Call stack at crash")
  end

  it "round-trips through JSON" do
    stack = Sarif::Stack.new(
      message: Sarif::Message.new(text: "stack trace"),
      frames: [
        Sarif::StackFrame.new(
          location: Sarif::Location.new(
            physical_location: Sarif::PhysicalLocation.new(
              artifact_location: Sarif::ArtifactLocation.new(uri: "main.cr"),
              region: Sarif::Region.new(start_line: 10)
            )
          ),
          module_name: "Main",
          thread_id: 1
        ),
        Sarif::StackFrame.new(
          location: Sarif::Location.new(
            physical_location: Sarif::PhysicalLocation.new(
              artifact_location: Sarif::ArtifactLocation.new(uri: "lib.cr"),
              region: Sarif::Region.new(start_line: 20)
            )
          ),
          module_name: "Lib"
        ),
      ]
    )
    restored = Sarif::Stack.from_json(stack.to_json)
    restored.message.not_nil!.text.should eq("stack trace")
    restored.frames.size.should eq(2)
    restored.frames[0].module_name.should eq("Main")
    restored.frames[1].module_name.should eq("Lib")
  end
end

describe Sarif::StackFrame do
  it "creates with defaults" do
    sf = Sarif::StackFrame.new
    sf.location.should be_nil
    sf.module_name.should be_nil
    sf.thread_id.should be_nil
    sf.parameters.should be_nil
  end

  it "creates with full details" do
    sf = Sarif::StackFrame.new(
      module_name: "MyApp",
      thread_id: 3,
      parameters: ["arg1", "arg2"]
    )
    sf.module_name.should eq("MyApp")
    sf.thread_id.should eq(3)
    sf.parameters.should eq(["arg1", "arg2"])
  end

  it "serializes with camelCase keys" do
    sf = Sarif::StackFrame.new(
      module_name: "Mod",
      thread_id: 7
    )
    json = sf.to_json
    parsed = JSON.parse(json)
    parsed["module"].as_s.should eq("Mod")
    parsed["threadId"].as_i.should eq(7)
  end

  it "round-trips through JSON" do
    sf = Sarif::StackFrame.new(
      location: Sarif::Location.new(
        physical_location: Sarif::PhysicalLocation.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "app.cr"),
          region: Sarif::Region.new(start_line: 50)
        )
      ),
      module_name: "App",
      thread_id: 1,
      parameters: ["x", "y"]
    )
    restored = Sarif::StackFrame.from_json(sf.to_json)
    restored.module_name.should eq("App")
    restored.thread_id.should eq(1)
    restored.parameters.should eq(["x", "y"])
    restored.location.not_nil!.physical_location.not_nil!.region.not_nil!.start_line.should eq(50)
  end
end
