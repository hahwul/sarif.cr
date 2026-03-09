require "../spec_helper"

describe Sarif::Message do
  it "creates with text" do
    msg = Sarif::Message.new(text: "Hello")
    msg.text.should eq("Hello")
    msg.markdown.should be_nil
    msg.id.should be_nil
    msg.arguments.should be_nil
  end

  it "serializes to JSON" do
    msg = Sarif::Message.new(text: "Error found", markdown: "**Error** found")
    json = msg.to_json
    parsed = JSON.parse(json)
    parsed["text"].as_s.should eq("Error found")
    parsed["markdown"].as_s.should eq("**Error** found")
  end

  it "omits nil fields from JSON" do
    msg = Sarif::Message.new(text: "Test")
    json = msg.to_json
    parsed = JSON.parse(json)
    parsed.as_h.has_key?("markdown").should be_false
    parsed.as_h.has_key?("id").should be_false
    parsed.as_h.has_key?("arguments").should be_false
  end

  it "deserializes from JSON" do
    json = %({ "text": "msg", "arguments": ["a", "b"] })
    msg = Sarif::Message.from_json(json)
    msg.text.should eq("msg")
    msg.arguments.should eq(["a", "b"])
  end

  it "round-trips through JSON" do
    msg = Sarif::Message.new(text: "test", id: "rule1", arguments: ["x"])
    restored = Sarif::Message.from_json(msg.to_json)
    restored.text.should eq("test")
    restored.id.should eq("rule1")
    restored.arguments.should eq(["x"])
  end
end
