require "../spec_helper"

describe Sarif::Notification do
  it "creates with message" do
    n = Sarif::Notification.new(message: Sarif::Message.new(text: "Analysis started"))
    n.message.text.should eq("Analysis started")
    n.level.should be_nil
    n.locations.should be_nil
  end

  it "creates with level and time" do
    n = Sarif::Notification.new(
      message: Sarif::Message.new(text: "Rule failed"),
      level: Sarif::NotificationLevel::Error,
      time_utc: "2024-01-01T12:00:00Z",
      thread_id: 1
    )
    n.level.should eq(Sarif::NotificationLevel::Error)
    n.time_utc.should eq("2024-01-01T12:00:00Z")
    n.thread_id.should eq(1)
  end

  it "serializes with camelCase keys" do
    n = Sarif::Notification.new(
      message: Sarif::Message.new(text: "warn"),
      level: Sarif::NotificationLevel::Warning,
      time_utc: "2024-01-01T00:00:00Z",
      thread_id: 42
    )
    json = n.to_json
    parsed = JSON.parse(json)
    parsed["level"].as_s.should eq("warning")
    parsed["timeUtc"].as_s.should eq("2024-01-01T00:00:00Z")
    parsed["threadId"].as_i.should eq(42)
  end

  it "supports exception" do
    n = Sarif::Notification.new(
      message: Sarif::Message.new(text: "Crash"),
      sarif_exception: Sarif::SarifException.new(
        kind: "NullPointerException",
        message: "null reference"
      )
    )
    json = n.to_json
    parsed = JSON.parse(json)
    parsed["exception"]["kind"].as_s.should eq("NullPointerException")
    parsed["exception"]["message"].as_s.should eq("null reference")
  end

  it "supports descriptor reference" do
    n = Sarif::Notification.new(
      message: Sarif::Message.new(text: "Rule notification"),
      descriptor: Sarif::ReportingDescriptorReference.new(id: "N001")
    )
    json = n.to_json
    parsed = JSON.parse(json)
    parsed["descriptor"]["id"].as_s.should eq("N001")
  end

  it "round-trips through JSON" do
    n = Sarif::Notification.new(
      message: Sarif::Message.new(text: "Analysis complete"),
      level: Sarif::NotificationLevel::Note,
      time_utc: "2024-06-01T00:00:00Z",
      thread_id: 5
    )
    restored = Sarif::Notification.from_json(n.to_json)
    restored.message.text.should eq("Analysis complete")
    restored.level.should eq(Sarif::NotificationLevel::Note)
    restored.time_utc.should eq("2024-06-01T00:00:00Z")
    restored.thread_id.should eq(5)
  end
end

describe Sarif::SarifException do
  it "creates with defaults" do
    e = Sarif::SarifException.new
    e.kind.should be_nil
    e.message.should be_nil
    e.stack.should be_nil
  end

  it "creates with details" do
    e = Sarif::SarifException.new(
      kind: "IOException",
      message: "File not found"
    )
    e.kind.should eq("IOException")
    e.message.should eq("File not found")
  end

  it "supports inner exceptions" do
    e = Sarif::SarifException.new(
      kind: "WrapperException",
      message: "outer",
      inner_exceptions: [
        Sarif::SarifException.new(kind: "RootCause", message: "inner"),
      ]
    )
    json = e.to_json
    parsed = JSON.parse(json)
    parsed["innerExceptions"][0]["kind"].as_s.should eq("RootCause")
  end

  it "supports stack" do
    e = Sarif::SarifException.new(
      kind: "RuntimeError",
      stack: Sarif::Stack.new(
        frames: [
          Sarif::StackFrame.new(
            location: Sarif::Location.new(
              physical_location: Sarif::PhysicalLocation.new(
                artifact_location: Sarif::ArtifactLocation.new(uri: "main.cr"),
                region: Sarif::Region.new(start_line: 42)
              )
            ),
            module_name: "App"
          ),
        ]
      )
    )
    json = e.to_json
    parsed = JSON.parse(json)
    parsed["stack"]["frames"][0]["module"].as_s.should eq("App")
  end

  it "round-trips through JSON" do
    e = Sarif::SarifException.new(
      kind: "TestError",
      message: "test failure",
      inner_exceptions: [Sarif::SarifException.new(kind: "Cause")]
    )
    restored = Sarif::SarifException.from_json(e.to_json)
    restored.kind.should eq("TestError")
    restored.message.should eq("test failure")
    restored.inner_exceptions.not_nil![0].kind.should eq("Cause")
  end
end
