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

    # The binary and character offsets use -1 as their "absent" sentinel; the
    # matching lengths have no sentinel and are simply non-negative.
    private def offsets_valid? : Bool
      if (bo = byte_offset) && bo < -1
        return false
      end
      if (co = char_offset) && co < -1
        return false
      end
      if (bl = byte_length) && bl < 0
        return false
      end
      if (cl = char_length) && cl < 0
        return false
      end
      true
    end

    def valid? : Bool
      if (sl = start_line) && sl < 1
        return false
      end
      if (sc = start_column) && sc < 1
        return false
      end
      if (el = end_line) && el < 1
        return false
      end
      if (ec = end_column) && ec < 1
        return false
      end
      return false unless offsets_valid?
      if (sl = start_line) && (el = end_line)
        return false if el < sl
        if el == sl && (sc = start_column) && (ec = end_column) && ec < sc
          return false
        end
      end
      true
    end
  end
end
