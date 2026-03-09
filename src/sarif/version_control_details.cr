require "json"

module Sarif
  class VersionControlDetails
    include JSON::Serializable

    @[JSON::Field(key: "repositoryUri")]
    property repository_uri : String

    @[JSON::Field(key: "revisionId")]
    property revision_id : String? = nil

    property branch : String? = nil

    @[JSON::Field(key: "revisionTag")]
    property revision_tag : String? = nil

    @[JSON::Field(key: "asOfTimeUtc")]
    property as_of_time_utc : String? = nil

    @[JSON::Field(key: "mappedTo")]
    property mapped_to : ArtifactLocation? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@repository_uri : String, @revision_id : String? = nil,
                   @branch : String? = nil, @revision_tag : String? = nil,
                   @as_of_time_utc : String? = nil, @mapped_to : ArtifactLocation? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
