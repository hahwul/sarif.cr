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

  it "handles type mismatch gracefully with []?" do
    bag = Sarif::PropertyBag.new
    bag["count"] = JSON::Any.new(42_i64)
    bag["count"]?.should_not be_nil
    bag["count"].as_i.should eq(42)
    # Accessing as wrong type raises
    expect_raises(Exception) do
      bag["count"].as_s
    end
  end

  it "supports boolean values" do
    bag = Sarif::PropertyBag.new
    bag["enabled"] = JSON::Any.new(true)
    json = bag.to_json
    restored = Sarif::PropertyBag.from_json(json)
    restored["enabled"].as_bool.should be_true
  end

  it "supports null values" do
    json = %({ "value": null })
    bag = Sarif::PropertyBag.from_json(json)
    bag["value"].raw.should be_nil
  end

  describe "typed accessors" do
    it "#get_string returns string value" do
      bag = Sarif::PropertyBag.new
      bag["name"] = JSON::Any.new("hello")
      bag.get_string("name").should eq("hello")
    end

    it "#get_string returns nil for non-string" do
      bag = Sarif::PropertyBag.new
      bag["count"] = JSON::Any.new(42_i64)
      bag.get_string("count").should be_nil
    end

    it "#get_string returns nil for missing key" do
      bag = Sarif::PropertyBag.new
      bag.get_string("missing").should be_nil
    end

    it "#get_string with default" do
      bag = Sarif::PropertyBag.new
      bag.get_string("missing", "default").should eq("default")
      bag["name"] = JSON::Any.new("value")
      bag.get_string("name", "default").should eq("value")
    end

    it "#get_int returns integer value" do
      bag = Sarif::PropertyBag.new
      bag["count"] = JSON::Any.new(42_i64)
      bag.get_int("count").should eq(42_i64)
    end

    it "#get_int returns nil for non-integer" do
      bag = Sarif::PropertyBag.new
      bag["name"] = JSON::Any.new("hello")
      bag.get_int("name").should be_nil
    end

    it "#get_int with default" do
      bag = Sarif::PropertyBag.new
      bag.get_int("missing", 0_i64).should eq(0_i64)
    end

    it "#get_float returns float value" do
      bag = Sarif::PropertyBag.new
      bag["score"] = JSON::Any.new(3.14)
      bag.get_float("score").should eq(3.14)
    end

    it "#get_float returns nil for non-number" do
      bag = Sarif::PropertyBag.new
      bag["name"] = JSON::Any.new("hello")
      bag.get_float("name").should be_nil
    end

    it "#get_float with default" do
      bag = Sarif::PropertyBag.new
      bag.get_float("missing", 0.0).should eq(0.0)
    end

    it "#get_bool returns boolean value" do
      bag = Sarif::PropertyBag.new
      bag["enabled"] = JSON::Any.new(true)
      bag.get_bool("enabled").should be_true
    end

    it "#get_bool returns nil for non-boolean" do
      bag = Sarif::PropertyBag.new
      bag["name"] = JSON::Any.new("hello")
      bag.get_bool("name").should be_nil
    end

    it "#get_bool with default" do
      bag = Sarif::PropertyBag.new
      bag.get_bool("missing", false).should be_false
      bag["flag"] = JSON::Any.new(true)
      bag.get_bool("flag", false).should be_true
    end
  end

  describe "utility methods" do
    it "#has_key? checks key existence" do
      bag = Sarif::PropertyBag.new
      bag["key"] = JSON::Any.new("val")
      bag.has_key?("key").should be_true
      bag.has_key?("other").should be_false
    end

    it "#size returns count of custom properties" do
      bag = Sarif::PropertyBag.new
      bag.size.should eq(0)
      bag["a"] = JSON::Any.new("1")
      bag["b"] = JSON::Any.new("2")
      bag.size.should eq(2)
    end

    it "#keys returns all custom property keys" do
      bag = Sarif::PropertyBag.new
      bag["x"] = JSON::Any.new("1")
      bag["y"] = JSON::Any.new("2")
      bag.keys.sort.should eq(["x", "y"])
    end
  end

  describe "#merge!" do
    it "merges properties from another bag" do
      bag1 = Sarif::PropertyBag.new
      bag1["a"] = JSON::Any.new("1")

      bag2 = Sarif::PropertyBag.new
      bag2["b"] = JSON::Any.new("2")

      bag1.merge!(bag2)
      bag1.get_string("a").should eq("1")
      bag1.get_string("b").should eq("2")
    end

    it "overwrites existing keys" do
      bag1 = Sarif::PropertyBag.new
      bag1["key"] = JSON::Any.new("old")

      bag2 = Sarif::PropertyBag.new
      bag2["key"] = JSON::Any.new("new")

      bag1.merge!(bag2)
      bag1.get_string("key").should eq("new")
    end

    it "merges tags without duplicates" do
      bag1 = Sarif::PropertyBag.new(tags: ["a", "b"])
      bag2 = Sarif::PropertyBag.new(tags: ["b", "c"])

      bag1.merge!(bag2)
      bag1.tags.not_nil!.sort.should eq(["a", "b", "c"])
    end
  end
end
