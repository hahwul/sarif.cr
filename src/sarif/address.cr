require "json"

module Sarif
  class Address
    include JSON::Serializable

    @[JSON::Field(key: "absoluteAddress")]
    property absolute_address : Int64? = nil

    @[JSON::Field(key: "relativeAddress")]
    property relative_address : Int64? = nil

    property length : Int64? = nil

    property kind : String? = nil

    property name : String? = nil

    @[JSON::Field(key: "fullyQualifiedName")]
    property fully_qualified_name : String? = nil

    @[JSON::Field(key: "offsetFromParent")]
    property offset_from_parent : Int64? = nil

    property index : Int32? = nil

    @[JSON::Field(key: "parentIndex")]
    property parent_index : Int32? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@absolute_address : Int64? = nil, @relative_address : Int64? = nil,
                   @length : Int64? = nil, @kind : String? = nil, @name : String? = nil,
                   @fully_qualified_name : String? = nil, @offset_from_parent : Int64? = nil,
                   @index : Int32? = nil, @parent_index : Int32? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
