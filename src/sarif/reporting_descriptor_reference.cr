require "json"

module Sarif
  class ReportingDescriptorReference
    include JSON::Serializable

    property id : String? = nil

    property index : Int32? = nil

    property guid : String? = nil

    @[JSON::Field(key: "toolComponent")]
    property tool_component : ToolComponentReference? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@id : String? = nil, @index : Int32? = nil,
                   @guid : String? = nil, @tool_component : ToolComponentReference? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
