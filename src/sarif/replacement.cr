require "json"

module Sarif
  class Replacement
    include JSON::Serializable

    @[JSON::Field(key: "deletedRegion")]
    property deleted_region : Region

    @[JSON::Field(key: "insertedContent")]
    property inserted_content : ArtifactContent? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@deleted_region : Region, @inserted_content : ArtifactContent? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
