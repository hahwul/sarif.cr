require "json"

module Sarif
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
  end
end
