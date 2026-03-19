require "json"

module Sarif
  class Message
    include JSON::Serializable

    property text : String? = nil

    property markdown : String? = nil

    property id : String? = nil

    property arguments : Array(String)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@text : String? = nil, @markdown : String? = nil, @id : String? = nil,
                   @arguments : Array(String)? = nil, @properties : PropertyBag? = nil)
    end

    def valid? : Bool
      !text.nil? || !id.nil?
    end
  end
end
