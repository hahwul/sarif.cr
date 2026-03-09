require "json"

module Sarif
  class ExternalPropertyFileReference
    include JSON::Serializable

    property location : ArtifactLocation? = nil

    property guid : String? = nil

    @[JSON::Field(key: "itemCount")]
    property item_count : Int32? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@location : ArtifactLocation? = nil, @guid : String? = nil,
                   @item_count : Int32? = nil, @properties : PropertyBag? = nil)
    end
  end
end
