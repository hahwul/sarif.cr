require "json"

module Sarif
  class Tool
    include JSON::Serializable

    property driver : ToolComponent

    property extensions : Array(ToolComponent)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@driver : ToolComponent, @extensions : Array(ToolComponent)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
