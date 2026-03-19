require "json"

module Sarif
  # Describes the analysis tool that produced a set of results.
  #
  # See: [SARIF 2.1.0 §3.18](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317529)
  class Tool
    include JSON::Serializable

    property driver : ToolComponent

    property extensions : Array(ToolComponent)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@driver : ToolComponent, @extensions : Array(ToolComponent)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
