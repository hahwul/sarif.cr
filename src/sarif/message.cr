require "json"

module Sarif
  # A message string or message ID with optional arguments.
  #
  # Per the SARIF spec, a message must have either `text` or `id` (or both).
  # Use `#valid?` to check this constraint.
  #
  # See: [SARIF 2.1.0 §3.11](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317459)
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
