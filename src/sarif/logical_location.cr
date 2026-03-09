require "json"

module Sarif
  class LogicalLocation
    include JSON::Serializable

    property name : String? = nil

    property index : Int32? = nil

    @[JSON::Field(key: "fullyQualifiedName")]
    property fully_qualified_name : String? = nil

    @[JSON::Field(key: "decoratedName")]
    property decorated_name : String? = nil

    @[JSON::Field(key: "parentIndex")]
    property parent_index : Int32? = nil

    property kind : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@name : String? = nil, @index : Int32? = nil,
                   @fully_qualified_name : String? = nil, @decorated_name : String? = nil,
                   @parent_index : Int32? = nil, @kind : String? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
