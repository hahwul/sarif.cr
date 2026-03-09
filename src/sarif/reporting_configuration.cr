require "json"

module Sarif
  class ReportingConfiguration
    include JSON::Serializable

    property enabled : Bool? = nil

    property level : Level? = nil

    property rank : Float64? = nil

    property parameters : PropertyBag? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@enabled : Bool? = nil, @level : Level? = nil,
                   @rank : Float64? = nil, @parameters : PropertyBag? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
