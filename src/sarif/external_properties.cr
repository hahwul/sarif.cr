require "json"

module Sarif
  class ExternalProperties
    include JSON::Serializable

    @[JSON::Field(key: "$schema")]
    property schema : String? = nil

    property version : String? = nil

    property guid : String? = nil

    @[JSON::Field(key: "runGuid")]
    property run_guid : String? = nil

    property conversion : Conversion? = nil

    property graphs : Array(Graph)? = nil

    @[JSON::Field(key: "externalizedProperties")]
    property externalized_properties : PropertyBag? = nil

    property artifacts : Array(Artifact)? = nil

    property invocations : Array(Invocation)? = nil

    @[JSON::Field(key: "logicalLocations")]
    property logical_locations : Array(LogicalLocation)? = nil

    @[JSON::Field(key: "threadFlowLocations")]
    property thread_flow_locations : Array(ThreadFlowLocation)? = nil

    property results : Array(Result)? = nil

    property taxonomies : Array(ToolComponent)? = nil

    property addresses : Array(Address)? = nil

    property driver : ToolComponent? = nil

    property extensions : Array(ToolComponent)? = nil

    property policies : Array(ToolComponent)? = nil

    property translations : Array(ToolComponent)? = nil

    @[JSON::Field(key: "webRequests")]
    property web_requests : Array(WebRequest)? = nil

    @[JSON::Field(key: "webResponses")]
    property web_responses : Array(WebResponse)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@schema : String? = nil, @version : String? = nil,
                   @guid : String? = nil, @run_guid : String? = nil,
                   @conversion : Conversion? = nil,
                   @graphs : Array(Graph)? = nil,
                   @externalized_properties : PropertyBag? = nil,
                   @artifacts : Array(Artifact)? = nil,
                   @invocations : Array(Invocation)? = nil,
                   @logical_locations : Array(LogicalLocation)? = nil,
                   @thread_flow_locations : Array(ThreadFlowLocation)? = nil,
                   @results : Array(Result)? = nil,
                   @taxonomies : Array(ToolComponent)? = nil,
                   @addresses : Array(Address)? = nil,
                   @driver : ToolComponent? = nil,
                   @extensions : Array(ToolComponent)? = nil,
                   @policies : Array(ToolComponent)? = nil,
                   @translations : Array(ToolComponent)? = nil,
                   @web_requests : Array(WebRequest)? = nil,
                   @web_responses : Array(WebResponse)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
