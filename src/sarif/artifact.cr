require "json"

module Sarif
  class Artifact
    include JSON::Serializable

    property location : ArtifactLocation? = nil

    property contents : ArtifactContent? = nil

    property roles : Array(ArtifactRole)? = nil

    property hashes : Hash(String, String)? = nil

    property length : Int64? = nil

    @[JSON::Field(key: "mimeType")]
    property mime_type : String? = nil

    property encoding : String? = nil

    @[JSON::Field(key: "sourceLanguage")]
    property source_language : String? = nil

    @[JSON::Field(key: "parentIndex")]
    property parent_index : Int32? = nil

    property offset : Int32? = nil

    property description : Message? = nil

    @[JSON::Field(key: "lastModifiedTimeUtc")]
    property last_modified_time_utc : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@location : ArtifactLocation? = nil, @contents : ArtifactContent? = nil,
                   @roles : Array(ArtifactRole)? = nil,
                   @hashes : Hash(String, String)? = nil,
                   @length : Int64? = nil, @mime_type : String? = nil,
                   @encoding : String? = nil, @source_language : String? = nil,
                   @parent_index : Int32? = nil, @offset : Int32? = nil,
                   @description : Message? = nil,
                   @last_modified_time_utc : String? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
