require "json"

module Sarif
  class SpecialLocations
    include JSON::Serializable

    @[JSON::Field(key: "displayBase")]
    property display_base : ArtifactLocation? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@display_base : ArtifactLocation? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
