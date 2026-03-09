require "json"

module Sarif
  class Attachment
    include JSON::Serializable

    property description : Message? = nil

    @[JSON::Field(key: "artifactLocation")]
    property artifact_location : ArtifactLocation

    property regions : Array(Region)? = nil

    property rectangles : Array(Rectangle)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@artifact_location : ArtifactLocation, @description : Message? = nil,
                   @regions : Array(Region)? = nil, @rectangles : Array(Rectangle)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
