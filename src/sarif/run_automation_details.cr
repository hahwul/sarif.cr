require "json"

module Sarif
  class RunAutomationDetails
    include JSON::Serializable

    property description : Message? = nil

    property id : String? = nil

    property guid : String? = nil

    @[JSON::Field(key: "correlationGuid")]
    property correlation_guid : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@description : Message? = nil, @id : String? = nil,
                   @guid : String? = nil, @correlation_guid : String? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
