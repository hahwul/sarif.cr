require "json"

module Sarif
  class WebRequest
    include JSON::Serializable

    property index : Int32? = nil

    property protocol : String? = nil

    property version : String? = nil

    property target : String? = nil

    property method : String? = nil

    property headers : Hash(String, String)? = nil

    property parameters : Hash(String, String)? = nil

    property body : ArtifactContent? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@index : Int32? = nil, @protocol : String? = nil,
                   @version : String? = nil, @target : String? = nil,
                   @method : String? = nil, @headers : Hash(String, String)? = nil,
                   @parameters : Hash(String, String)? = nil,
                   @body : ArtifactContent? = nil, @properties : PropertyBag? = nil)
    end
  end
end
