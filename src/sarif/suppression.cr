require "json"

module Sarif
  class Suppression
    include JSON::Serializable

    property kind : SuppressionKind

    property status : SuppressionStatus? = nil

    property location : Location? = nil

    property guid : String? = nil

    property justification : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@kind : SuppressionKind, @status : SuppressionStatus? = nil,
                   @location : Location? = nil, @guid : String? = nil,
                   @justification : String? = nil, @properties : PropertyBag? = nil)
    end
  end
end
