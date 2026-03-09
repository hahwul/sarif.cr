require "json"

module Sarif
  class Node
    include JSON::Serializable

    property id : String

    property label : Message? = nil

    property location : Location? = nil

    property children : Array(Node)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@id : String, @label : Message? = nil, @location : Location? = nil,
                   @children : Array(Node)? = nil, @properties : PropertyBag? = nil)
    end
  end
end
