require "../spec_helper"

describe Sarif::Replacement do
  it "creates with required deleted region" do
    r = Sarif::Replacement.new(
      deleted_region: Sarif::Region.new(start_line: 5, end_line: 5, start_column: 1, end_column: 10)
    )
    r.deleted_region.start_line.should eq(5)
    r.deleted_region.end_column.should eq(10)
  end

  it "creates with inserted content" do
    r = Sarif::Replacement.new(
      deleted_region: Sarif::Region.new(byte_offset: 100, byte_length: 20),
      inserted_content: Sarif::ArtifactContent.new(text: "new code")
    )
    r.inserted_content.not_nil!.text.should eq("new code")
  end

  it "defaults optional fields to nil" do
    r = Sarif::Replacement.new(deleted_region: Sarif::Region.new(start_line: 1))
    r.inserted_content.should be_nil
    r.properties.should be_nil
  end

  it "serializes with camelCase keys" do
    r = Sarif::Replacement.new(
      deleted_region: Sarif::Region.new(start_line: 1, end_line: 2),
      inserted_content: Sarif::ArtifactContent.new(text: "fix")
    )
    json = r.to_json
    parsed = JSON.parse(json)
    parsed["deletedRegion"]["startLine"].as_i.should eq(1)
    parsed["insertedContent"]["text"].as_s.should eq("fix")
  end

  it "round-trips through JSON" do
    r = Sarif::Replacement.new(
      deleted_region: Sarif::Region.new(byte_offset: 50, byte_length: 10),
      inserted_content: Sarif::ArtifactContent.new(text: "replacement text")
    )
    json = r.to_json
    restored = Sarif::Replacement.from_json(json)
    restored.deleted_region.byte_offset.should eq(50)
    restored.deleted_region.byte_length.should eq(10)
    restored.inserted_content.not_nil!.text.should eq("replacement text")
  end

  it "supports property bag" do
    bag = Sarif::PropertyBag.new
    bag["reason"] = JSON::Any.new("formatting")
    r = Sarif::Replacement.new(
      deleted_region: Sarif::Region.new(start_line: 1),
      properties: bag
    )
    json = r.to_json
    restored = Sarif::Replacement.from_json(json)
    restored.properties.not_nil!["reason"].as_s.should eq("formatting")
  end
end
