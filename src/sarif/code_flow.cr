require "json"

module Sarif
  class CodeFlow
    include JSON::Serializable

    property message : Message? = nil

    @[JSON::Field(key: "threadFlows")]
    property thread_flows : Array(ThreadFlow)

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@thread_flows : Array(ThreadFlow), @message : Message? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
