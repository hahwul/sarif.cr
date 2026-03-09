require "json"

module Sarif
  class MultiformatMessageString
    include JSON::Serializable

    property text : String

    property markdown : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@text : String, @markdown : String? = nil, @properties : PropertyBag? = nil)
    end
  end
end
