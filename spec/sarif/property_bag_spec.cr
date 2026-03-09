require "../spec_helper"

describe Sarif::PropertyBag do
  it "serializes empty property bag" do
    bag = Sarif::PropertyBag.new
    json = bag.to_json
    parsed = JSON.parse(json)
    parsed.as_h.size.should eq(0)
  end

  it "serializes with tags" do
    bag = Sarif::PropertyBag.new(tags: ["security", "bug"])
    json = bag.to_json
    parsed = JSON.parse(json)
    parsed["tags"].as_a.map(&.as_s).should eq(["security", "bug"])
  end

  it "stores arbitrary properties" do
    bag = Sarif::PropertyBag.new
    bag["custom"] = JSON::Any.new("value")
    bag["count"] = JSON::Any.new(42_i64)

    json = bag.to_json
    parsed = JSON.parse(json)
    parsed["custom"].as_s.should eq("value")
    parsed["count"].as_i.should eq(42)
  end

  it "deserializes with unmapped properties" do
    json = %({ "tags": ["a"], "custom": "hello", "nested": { "key": "val" } })
    bag = Sarif::PropertyBag.from_json(json)
    bag.tags.should eq(["a"])
    bag["custom"].as_s.should eq("hello")
    bag["nested"]["key"].as_s.should eq("val")
  end

  it "round-trips through JSON" do
    bag = Sarif::PropertyBag.new(tags: ["test"])
    bag["extra"] = JSON::Any.new("data")
    json = bag.to_json
    restored = Sarif::PropertyBag.from_json(json)
    restored.tags.should eq(["test"])
    restored["extra"].as_s.should eq("data")
  end

  it "returns nil for missing keys" do
    bag = Sarif::PropertyBag.new
    bag["missing"]?.should be_nil
  end
end
