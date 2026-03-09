require "json"

module Sarif
  class GraphTraversal
    include JSON::Serializable

    @[JSON::Field(key: "runGraphIndex")]
    property run_graph_index : Int32? = nil

    @[JSON::Field(key: "resultGraphIndex")]
    property result_graph_index : Int32? = nil

    property description : Message? = nil

    @[JSON::Field(key: "initialState")]
    property initial_state : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "immutableState")]
    property immutable_state : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "edgeTraversals")]
    property edge_traversals : Array(EdgeTraversal)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@run_graph_index : Int32? = nil, @result_graph_index : Int32? = nil,
                   @description : Message? = nil,
                   @initial_state : Hash(String, MultiformatMessageString)? = nil,
                   @immutable_state : Hash(String, MultiformatMessageString)? = nil,
                   @edge_traversals : Array(EdgeTraversal)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
