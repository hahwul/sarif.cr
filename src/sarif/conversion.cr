require "json"

module Sarif
  class Conversion
    include JSON::Serializable

    property tool : Tool

    property invocation : Invocation? = nil

    @[JSON::Field(key: "analysisToolLogFiles")]
    property analysis_tool_log_files : Array(ArtifactLocation)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@tool : Tool, @invocation : Invocation? = nil,
                   @analysis_tool_log_files : Array(ArtifactLocation)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
