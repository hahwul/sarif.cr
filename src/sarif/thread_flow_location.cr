require "json"

module Sarif
  class ThreadFlowLocation
    include JSON::Serializable

    property index : Int32? = nil

    property location : Location? = nil

    property stack : Stack? = nil

    property kinds : Array(String)? = nil

    property taxa : Array(ReportingDescriptorReference)? = nil

    @[JSON::Field(key: "module")]
    property module_name : String? = nil

    property state : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "nestingLevel")]
    property nesting_level : Int32? = nil

    @[JSON::Field(key: "executionOrder")]
    property execution_order : Int32? = nil

    @[JSON::Field(key: "executionTimeUtc")]
    property execution_time_utc : String? = nil

    property importance : Importance? = nil

    @[JSON::Field(key: "webRequest")]
    property web_request : WebRequest? = nil

    @[JSON::Field(key: "webResponse")]
    property web_response : WebResponse? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@index : Int32? = nil, @location : Location? = nil,
                   @stack : Stack? = nil, @kinds : Array(String)? = nil,
                   @taxa : Array(ReportingDescriptorReference)? = nil,
                   @module_name : String? = nil,
                   @state : Hash(String, MultiformatMessageString)? = nil,
                   @nesting_level : Int32? = nil, @execution_order : Int32? = nil,
                   @execution_time_utc : String? = nil, @importance : Importance? = nil,
                   @web_request : WebRequest? = nil, @web_response : WebResponse? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
