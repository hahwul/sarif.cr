require "json"

module Sarif
  class Edge
    include JSON::Serializable

    property id : String

    @[JSON::Field(key: "sourceNodeId")]
    property source_node_id : String

    @[JSON::Field(key: "targetNodeId")]
    property target_node_id : String

    property label : Message? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@id : String, @source_node_id : String, @target_node_id : String,
                   @label : Message? = nil, @properties : PropertyBag? = nil)
    end
  end
end
