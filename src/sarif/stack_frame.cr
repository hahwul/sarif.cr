require "json"

module Sarif
  class StackFrame
    include JSON::Serializable

    property location : Location? = nil

    @[JSON::Field(key: "module")]
    property module_name : String? = nil

    @[JSON::Field(key: "threadId")]
    property thread_id : Int32? = nil

    property parameters : Array(String)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@location : Location? = nil, @module_name : String? = nil,
                   @thread_id : Int32? = nil, @parameters : Array(String)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
