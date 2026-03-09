require "json"

module Sarif
  class SarifException
    include JSON::Serializable

    property kind : String? = nil

    property message : String? = nil

    property stack : Stack? = nil

    @[JSON::Field(key: "innerExceptions")]
    property inner_exceptions : Array(SarifException)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@kind : String? = nil, @message : String? = nil,
                   @stack : Stack? = nil, @inner_exceptions : Array(SarifException)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
