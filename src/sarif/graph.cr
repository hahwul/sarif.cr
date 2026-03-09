require "json"

module Sarif
  class Graph
    include JSON::Serializable

    property description : Message? = nil

    property nodes : Array(Node)? = nil

    property edges : Array(Edge)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@description : Message? = nil, @nodes : Array(Node)? = nil,
                   @edges : Array(Edge)? = nil, @properties : PropertyBag? = nil)
    end
  end
end
