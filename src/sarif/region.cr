require "json"

module Sarif
  class Region
    include JSON::Serializable

    @[JSON::Field(key: "startLine")]
    property start_line : Int32? = nil

    @[JSON::Field(key: "startColumn")]
    property start_column : Int32? = nil

    @[JSON::Field(key: "endLine")]
    property end_line : Int32? = nil

    @[JSON::Field(key: "endColumn")]
    property end_column : Int32? = nil

    @[JSON::Field(key: "byteOffset")]
    property byte_offset : Int32? = nil

    @[JSON::Field(key: "byteLength")]
    property byte_length : Int32? = nil

    @[JSON::Field(key: "charOffset")]
    property char_offset : Int32? = nil

    @[JSON::Field(key: "charLength")]
    property char_length : Int32? = nil

    property snippet : ArtifactContent? = nil

    property message : Message? = nil

    @[JSON::Field(key: "sourceLanguage")]
    property source_language : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@start_line : Int32? = nil, @start_column : Int32? = nil,
                   @end_line : Int32? = nil, @end_column : Int32? = nil,
                   @byte_offset : Int32? = nil, @byte_length : Int32? = nil,
                   @char_offset : Int32? = nil, @char_length : Int32? = nil,
                   @snippet : ArtifactContent? = nil, @message : Message? = nil,
                   @source_language : String? = nil, @properties : PropertyBag? = nil)
    end
  end
end
