require "json"

module Sarif
  class EdgeTraversal
    include JSON::Serializable

    @[JSON::Field(key: "edgeId")]
    property edge_id : String

    property message : Message? = nil

    @[JSON::Field(key: "finalState")]
    property final_state : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "stepOverEdgeCount")]
    property step_over_edge_count : Int32? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@edge_id : String, @message : Message? = nil,
                   @final_state : Hash(String, MultiformatMessageString)? = nil,
                   @step_over_edge_count : Int32? = nil, @properties : PropertyBag? = nil)
    end
  end
end
