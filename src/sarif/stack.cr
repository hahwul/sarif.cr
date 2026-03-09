require "json"

module Sarif
  class Stack
    include JSON::Serializable

    property message : Message? = nil

    property frames : Array(StackFrame)

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@frames : Array(StackFrame), @message : Message? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
