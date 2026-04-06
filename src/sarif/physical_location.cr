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

    def valid? : Bool
      return false if artifact_location.nil? && address.nil?
      if (r = region) && !r.valid?
        return false
      end
      if (cr = context_region) && !cr.valid?
        return false
      end
      true
    end
  end
end
