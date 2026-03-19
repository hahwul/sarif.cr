require "json"

module Sarif
  # A property bag for storing arbitrary key-value pairs.
  #
  # Supports both dynamic access via `[]`/`[]=` and typed accessors
  # (`get_string`, `get_int`, `get_bool`, `get_float`) for safe retrieval.
  #
  # See: [SARIF 2.1.0 §3.8](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317448)
  class PropertyBag
    include JSON::Serializable
    include JSON::Serializable::Unmapped

    @[JSON::Field(key: "tags")]
    property tags : Array(String)? = nil

    def initialize(@tags : Array(String)? = nil)
    end

    def []=(key : String, value : JSON::Any)
      json_unmapped[key] = value
    end

    def []?(key : String) : JSON::Any?
      json_unmapped[key]?
    end

    def [](key : String) : JSON::Any
      json_unmapped[key]
    end

    # Returns the value as a String, or nil if the key is missing or not a string.
    def get_string(key : String) : String?
      json_unmapped[key]?.try &.as_s?
    end

    # Returns the value as a String, or the default if the key is missing or not a string.
    def get_string(key : String, default : String) : String
      get_string(key) || default
    end

    # Returns the value as an Int64, or nil if the key is missing or not an integer.
    def get_int(key : String) : Int64?
      json_unmapped[key]?.try &.as_i64?
    end

    # Returns the value as an Int64, or the default if the key is missing or not an integer.
    def get_int(key : String, default : Int64) : Int64
      get_int(key) || default
    end

    # Returns the value as a Float64, or nil if the key is missing or not a number.
    def get_float(key : String) : Float64?
      json_unmapped[key]?.try &.as_f?
    end

    # Returns the value as a Float64, or the default if the key is missing or not a number.
    def get_float(key : String, default : Float64) : Float64
      get_float(key) || default
    end

    # Returns the value as a Bool, or nil if the key is missing or not a boolean.
    def get_bool(key : String) : Bool?
      json_unmapped[key]?.try &.as_bool?
    end

    # Returns the value as a Bool, or the default if the key is missing or not a boolean.
    def get_bool(key : String, default : Bool) : Bool
      v = get_bool(key)
      v.nil? ? default : v
    end

    # Returns true if the given key exists in this property bag.
    def has_key?(key : String) : Bool
      json_unmapped.has_key?(key)
    end

    # Returns the number of custom properties (excluding tags).
    def size : Int32
      json_unmapped.size
    end

    # Returns all custom property keys.
    def keys : Array(String)
      json_unmapped.keys
    end

    # Merges another PropertyBag into this one. Existing keys are overwritten.
    def merge!(other : PropertyBag) : self
      other.json_unmapped.each do |key, value|
        json_unmapped[key] = value
      end
      if other_tags = other.tags
        existing = @tags ||= [] of String
        other_tags.each do |tag|
          existing << tag unless existing.includes?(tag)
        end
      end
      self
    end
  end
end
