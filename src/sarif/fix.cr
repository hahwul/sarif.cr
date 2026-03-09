require "json"

module Sarif
  class Fix
    include JSON::Serializable

    property description : Message? = nil

    @[JSON::Field(key: "artifactChanges")]
    property artifact_changes : Array(ArtifactChange)

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@artifact_changes : Array(ArtifactChange), @description : Message? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
