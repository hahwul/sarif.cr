require "json"

module Sarif
  class ThreadFlow
    include JSON::Serializable

    property id : String? = nil

    property message : Message? = nil

    property locations : Array(ThreadFlowLocation)

    @[JSON::Field(key: "initialState")]
    property initial_state : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "immutableState")]
    property immutable_state : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@locations : Array(ThreadFlowLocation), @id : String? = nil,
                   @message : Message? = nil,
                   @initial_state : Hash(String, MultiformatMessageString)? = nil,
                   @immutable_state : Hash(String, MultiformatMessageString)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
