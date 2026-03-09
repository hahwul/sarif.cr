require "json"

module Sarif
  class Rectangle
    include JSON::Serializable

    property top : Float64? = nil
    property left : Float64? = nil
    property bottom : Float64? = nil
    property right : Float64? = nil

    property message : Message? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@top : Float64? = nil, @left : Float64? = nil,
                   @bottom : Float64? = nil, @right : Float64? = nil,
                   @message : Message? = nil, @properties : PropertyBag? = nil)
    end
  end
end
