require "json"

module Sarif
  SARIF_VERSION = "2.1.0"
  SARIF_SCHEMA  = "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json"

  class SarifLog
    include JSON::Serializable

    property version : String

    @[JSON::Field(key: "$schema")]
    property schema : String? = nil

    property runs : Array(Run)

    @[JSON::Field(key: "inlineExternalProperties")]
    property inline_external_properties : Array(ExternalProperties)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@runs : Array(Run), @version : String = SARIF_VERSION,
                   @schema : String? = SARIF_SCHEMA,
                   @inline_external_properties : Array(ExternalProperties)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
