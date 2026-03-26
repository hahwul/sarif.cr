require "../spec_helper"

describe Sarif::MultiformatMessageString do
  it "creates with text only" do
    mms = Sarif::MultiformatMessageString.new(text: "hello")
    mms.text.should eq("hello")
    mms.markdown.should be_nil
  end

  it "creates with text and markdown" do
    mms = Sarif::MultiformatMessageString.new(text: "hello", markdown: "**hello**")
    mms.text.should eq("hello")
    mms.markdown.should eq("**hello**")
  end

  it "round-trips through JSON" do
    mms = Sarif::MultiformatMessageString.new(text: "Error found", markdown: "**Error** found")
    restored = Sarif::MultiformatMessageString.from_json(mms.to_json)
    restored.text.should eq("Error found")
    restored.markdown.should eq("**Error** found")
  end
end
