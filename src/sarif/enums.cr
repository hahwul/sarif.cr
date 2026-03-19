module Sarif
  # Macro for defining SARIF enums with bidirectional JSON serialization.
  # Maps Crystal enum values to their camelCase SARIF string representations.
  macro sarif_enum(name, mapping)
    enum {{name}}
      {% for key, _value in mapping %}
        {{key}}
      {% end %}

      def to_json(json : JSON::Builder) : Nil
        json.string(to_s_sarif)
      end

      def to_s_sarif : String
        case self
        {% for key, value in mapping %}
        when {{key}} then {{value}}
        {% end %}
        else
          raise "Unknown #{self.class} value: #{self}"
        end
      end

      def self.from_json(pull : JSON::PullParser) : self
        str = pull.read_string
        case str
        {% for key, value in mapping %}
        when {{value}} then {{key}}
        {% end %}
        else
          raise "Unknown #{self} value: #{str}"
        end
      end

      def self.parse_sarif(str : String) : self
        case str
        {% for key, value in mapping %}
        when {{value}} then {{key}}
        {% end %}
        else
          raise "Unknown #{self} value: #{str}"
        end
      end
    end
  end

  # Severity level of a result. See: SARIF 2.1.0 §3.27.10
  sarif_enum(Level, {
    None    => "none",
    Note    => "note",
    Warning => "warning",
    Error   => "error",
  })

  sarif_enum(ResultKind, {
    NotApplicable => "notApplicable",
    Pass          => "pass",
    Fail          => "fail",
    Review        => "review",
    Open          => "open",
    Informational => "informational",
  })

  sarif_enum(BaselineState, {
    New       => "new",
    Unchanged => "unchanged",
    Updated   => "updated",
    Absent    => "absent",
  })

  sarif_enum(SuppressionKind, {
    InSource => "inSource",
    External => "external",
  })

  sarif_enum(SuppressionStatus, {
    Accepted    => "accepted",
    UnderReview => "underReview",
    Rejected    => "rejected",
  })

  sarif_enum(Importance, {
    Important   => "important",
    Essential   => "essential",
    Unimportant => "unimportant",
  })

  sarif_enum(ArtifactRole, {
    AnalysisTarget             => "analysisTarget",
    Attachment                 => "attachment",
    ResponseFile               => "responseFile",
    ResultFile                 => "resultFile",
    StandardStream             => "standardStream",
    TracedFile                 => "tracedFile",
    Unmodified                 => "unmodified",
    Modified                   => "modified",
    Added                      => "added",
    Deleted                    => "deleted",
    Renamed                    => "renamed",
    Uncontrolled               => "uncontrolled",
    Driver                     => "driver",
    Extension                  => "extension",
    Translation                => "translation",
    Taxonomy                   => "taxonomy",
    Policy                     => "policy",
    ReferencedOnCommandLine    => "referencedOnCommandLine",
    MemoryContents             => "memoryContents",
    Directory                  => "directory",
    UserSpecifiedConfiguration => "userSpecifiedConfiguration",
    ToolSpecifiedConfiguration => "toolSpecifiedConfiguration",
    DebugOutputFile            => "debugOutputFile",
  })

  sarif_enum(ColumnKind, {
    Utf16CodeUnits    => "utf16CodeUnits",
    UnicodeCodePoints => "unicodeCodePoints",
  })

  sarif_enum(ToolComponentContent, {
    LocalizedData    => "localizedData",
    NonLocalizedData => "nonLocalizedData",
  })

  sarif_enum(NotificationLevel, {
    None    => "none",
    Note    => "note",
    Warning => "warning",
    Error   => "error",
  })
end
