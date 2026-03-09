require "json"

module Sarif
  class WebResponse
    include JSON::Serializable

    property index : Int32? = nil

    property protocol : String? = nil

    property version : String? = nil

    @[JSON::Field(key: "statusCode")]
    property status_code : Int32? = nil

    @[JSON::Field(key: "reasonPhrase")]
    property reason_phrase : String? = nil

    property headers : Hash(String, String)? = nil

    property body : ArtifactContent? = nil

    @[JSON::Field(key: "noResponseReceived")]
    property no_response_received : Bool? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@index : Int32? = nil, @protocol : String? = nil,
                   @version : String? = nil, @status_code : Int32? = nil,
                   @reason_phrase : String? = nil, @headers : Hash(String, String)? = nil,
                   @body : ArtifactContent? = nil, @no_response_received : Bool? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
