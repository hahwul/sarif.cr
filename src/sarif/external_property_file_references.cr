require "json"

module Sarif
  class ExternalPropertyFileReferences
    include JSON::Serializable

    property conversion : ExternalPropertyFileReference? = nil

    property graphs : Array(ExternalPropertyFileReference)? = nil

    @[JSON::Field(key: "externalizedProperties")]
    property externalized_properties : ExternalPropertyFileReference? = nil

    property artifacts : Array(ExternalPropertyFileReference)? = nil

    property invocations : Array(ExternalPropertyFileReference)? = nil

    @[JSON::Field(key: "logicalLocations")]
    property logical_locations : Array(ExternalPropertyFileReference)? = nil

    @[JSON::Field(key: "threadFlowLocations")]
    property thread_flow_locations : Array(ExternalPropertyFileReference)? = nil

    property results : Array(ExternalPropertyFileReference)? = nil

    property taxonomies : Array(ExternalPropertyFileReference)? = nil

    property addresses : Array(ExternalPropertyFileReference)? = nil

    property driver : ExternalPropertyFileReference? = nil

    property extensions : Array(ExternalPropertyFileReference)? = nil

    property policies : Array(ExternalPropertyFileReference)? = nil

    property translations : Array(ExternalPropertyFileReference)? = nil

    @[JSON::Field(key: "webRequests")]
    property web_requests : Array(ExternalPropertyFileReference)? = nil

    @[JSON::Field(key: "webResponses")]
    property web_responses : Array(ExternalPropertyFileReference)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@conversion : ExternalPropertyFileReference? = nil,
                   @graphs : Array(ExternalPropertyFileReference)? = nil,
                   @externalized_properties : ExternalPropertyFileReference? = nil,
                   @artifacts : Array(ExternalPropertyFileReference)? = nil,
                   @invocations : Array(ExternalPropertyFileReference)? = nil,
                   @logical_locations : Array(ExternalPropertyFileReference)? = nil,
                   @thread_flow_locations : Array(ExternalPropertyFileReference)? = nil,
                   @results : Array(ExternalPropertyFileReference)? = nil,
                   @taxonomies : Array(ExternalPropertyFileReference)? = nil,
                   @addresses : Array(ExternalPropertyFileReference)? = nil,
                   @driver : ExternalPropertyFileReference? = nil,
                   @extensions : Array(ExternalPropertyFileReference)? = nil,
                   @policies : Array(ExternalPropertyFileReference)? = nil,
                   @translations : Array(ExternalPropertyFileReference)? = nil,
                   @web_requests : Array(ExternalPropertyFileReference)? = nil,
                   @web_responses : Array(ExternalPropertyFileReference)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
