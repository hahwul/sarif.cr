require "json"

module Sarif
  class ReportingDescriptorRelationship
    include JSON::Serializable

    property target : ReportingDescriptorReference

    property kinds : Array(String)? = nil

    property description : Message? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@target : ReportingDescriptorReference, @kinds : Array(String)? = nil,
                   @description : Message? = nil, @properties : PropertyBag? = nil)
    end
  end
end
