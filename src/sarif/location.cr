require "json"

module Sarif
  class Location
    include JSON::Serializable

    property id : Int32? = nil

    @[JSON::Field(key: "physicalLocation")]
    property physical_location : PhysicalLocation? = nil

    @[JSON::Field(key: "logicalLocations")]
    property logical_locations : Array(LogicalLocation)? = nil

    property message : Message? = nil

    property annotations : Array(Region)? = nil

    property relationships : Array(LocationRelationship)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@id : Int32? = nil, @physical_location : PhysicalLocation? = nil,
                   @logical_locations : Array(LogicalLocation)? = nil,
                   @message : Message? = nil, @annotations : Array(Region)? = nil,
                   @relationships : Array(LocationRelationship)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
