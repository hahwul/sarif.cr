require "json"

module Sarif
  class ToolComponentReference
    include JSON::Serializable

    property name : String? = nil

    property index : Int32? = nil

    property guid : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@name : String? = nil, @index : Int32? = nil,
                   @guid : String? = nil, @properties : PropertyBag? = nil)
    end
  end
end
