require "json"

module Sarif
  class PhysicalLocation
    include JSON::Serializable

    @[JSON::Field(key: "artifactLocation")]
    property artifact_location : ArtifactLocation? = nil

    property region : Region? = nil

    @[JSON::Field(key: "contextRegion")]
    property context_region : Region? = nil

    property address : Address? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@artifact_location : ArtifactLocation? = nil, @region : Region? = nil,
                   @context_region : Region? = nil, @address : Address? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
