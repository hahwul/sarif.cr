require "../spec_helper"

describe Sarif::Region do
  it "creates a region with line and column info" do
    region = Sarif::Region.new(start_line: 10, start_column: 5, end_line: 20, end_column: 15)
    region.start_line.should eq(10)
    region.start_column.should eq(5)
    region.end_line.should eq(20)
    region.end_column.should eq(15)
  end

  it "creates a region with byte offset and length" do
    region = Sarif::Region.new(byte_offset: 100, byte_length: 50)
    region.byte_offset.should eq(100)
    region.byte_length.should eq(50)
  end

  it "creates a region with char offset and length" do
    region = Sarif::Region.new(char_offset: 200, char_length: 30)
    region.char_offset.should eq(200)
    region.char_length.should eq(30)
  end

  it "defaults all fields to nil" do
    region = Sarif::Region.new
    region.start_line.should be_nil
    region.start_column.should be_nil
    region.end_line.should be_nil
    region.end_column.should be_nil
    region.byte_offset.should be_nil
    region.byte_length.should be_nil
    region.char_offset.should be_nil
    region.char_length.should be_nil
    region.snippet.should be_nil
    region.message.should be_nil
    region.source_language.should be_nil
    region.properties.should be_nil
  end

  it "supports snippet and message" do
    region = Sarif::Region.new(
      start_line: 1,
      snippet: Sarif::ArtifactContent.new(text: "x = 1"),
      message: Sarif::Message.new(text: "assignment")
    )
    region.snippet.not_nil!.text.should eq("x = 1")
    region.message.not_nil!.text.should eq("assignment")
  end

  it "supports source language" do
    region = Sarif::Region.new(start_line: 1, source_language: "crystal")
    region.source_language.should eq("crystal")
  end

  it "serializes with camelCase keys" do
    region = Sarif::Region.new(start_line: 1, start_column: 2, end_line: 3, end_column: 4)
    json = region.to_json
    parsed = JSON.parse(json)
    parsed["startLine"].as_i.should eq(1)
    parsed["startColumn"].as_i.should eq(2)
    parsed["endLine"].as_i.should eq(3)
    parsed["endColumn"].as_i.should eq(4)
  end

  it "serializes byte/char fields with camelCase" do
    region = Sarif::Region.new(byte_offset: 10, byte_length: 20, char_offset: 5, char_length: 15)
    json = region.to_json
    parsed = JSON.parse(json)
    parsed["byteOffset"].as_i.should eq(10)
    parsed["byteLength"].as_i.should eq(20)
    parsed["charOffset"].as_i.should eq(5)
    parsed["charLength"].as_i.should eq(15)
  end

  it "round-trips through JSON" do
    region = Sarif::Region.new(
      start_line: 5, start_column: 3, end_line: 10, end_column: 20,
      byte_offset: 100, byte_length: 50,
      source_language: "crystal"
    )
    json = region.to_json
    restored = Sarif::Region.from_json(json)
    restored.start_line.should eq(5)
    restored.start_column.should eq(3)
    restored.end_line.should eq(10)
    restored.end_column.should eq(20)
    restored.byte_offset.should eq(100)
    restored.byte_length.should eq(50)
    restored.source_language.should eq("crystal")
  end

  it "omits nil fields from JSON" do
    region = Sarif::Region.new(start_line: 1)
    json = region.to_json
    parsed = JSON.parse(json)
    parsed["startLine"].as_i.should eq(1)
    parsed["endLine"]?.should be_nil
    parsed["startColumn"]?.should be_nil
  end

  describe "#valid?" do
    it "returns true for a valid region" do
      Sarif::Region.new(start_line: 1, end_line: 10).valid?.should be_true
    end

    it "returns true for an empty region" do
      Sarif::Region.new.valid?.should be_true
    end

    it "returns false when startLine < 1" do
      Sarif::Region.new(start_line: 0).valid?.should be_false
    end

    it "returns false when startColumn < 1" do
      Sarif::Region.new(start_column: 0).valid?.should be_false
    end

    it "returns false when endLine < 1" do
      Sarif::Region.new(end_line: 0).valid?.should be_false
    end

    it "returns false when endColumn < 1" do
      Sarif::Region.new(end_column: 0).valid?.should be_false
    end

    it "returns false when endLine < startLine" do
      Sarif::Region.new(start_line: 10, end_line: 5).valid?.should be_false
    end

    it "returns false when endColumn < startColumn on same line" do
      Sarif::Region.new(start_line: 5, end_line: 5, start_column: 10, end_column: 3).valid?.should be_false
    end

    it "returns true when endColumn < startColumn on different lines" do
      Sarif::Region.new(start_line: 5, end_line: 10, start_column: 10, end_column: 3).valid?.should be_true
    end
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["tag"] = JSON::Any.new("test")
    region = Sarif::Region.new(start_line: 1, properties: bag)
    json = region.to_json
    restored = Sarif::Region.from_json(json)
    restored.properties.not_nil!["tag"].as_s.should eq("test")
  end
end
