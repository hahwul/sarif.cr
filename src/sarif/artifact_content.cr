require "json"

module Sarif
  class ArtifactContent
    include JSON::Serializable

    property text : String? = nil

    property binary : String? = nil

    property rendered : MultiformatMessageString? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@text : String? = nil, @binary : String? = nil,
                   @rendered : MultiformatMessageString? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
