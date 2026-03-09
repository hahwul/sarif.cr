require "json"

module Sarif
  class LocationRelationship
    include JSON::Serializable

    property target : Int32

    property kinds : Array(String)? = nil

    property description : Message? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@target : Int32, @kinds : Array(String)? = nil,
                   @description : Message? = nil, @properties : PropertyBag? = nil)
    end
  end
end
