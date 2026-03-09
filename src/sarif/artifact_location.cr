require "json"

module Sarif
  class ArtifactLocation
    include JSON::Serializable

    property uri : String? = nil

    @[JSON::Field(key: "uriBaseId")]
    property uri_base_id : String? = nil

    property index : Int32? = nil

    property description : Message? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@uri : String? = nil, @uri_base_id : String? = nil,
                   @index : Int32? = nil, @description : Message? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
