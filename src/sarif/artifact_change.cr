require "json"

module Sarif
  class ArtifactChange
    include JSON::Serializable

    @[JSON::Field(key: "artifactLocation")]
    property artifact_location : ArtifactLocation

    property replacements : Array(Replacement)

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@artifact_location : ArtifactLocation, @replacements : Array(Replacement),
                   @properties : PropertyBag? = nil)
    end
  end
end
