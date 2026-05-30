module Sarif
  # The sentinel string that the `Unknown` member of every `sarif_enum`
  # serializes to. No real SARIF 2.1.0 enum value uses this token, so it is
  # safe to use as a round-trippable placeholder for values outside the known
  # set (forward/backward compat values, vendor extensions, typos, etc.).
  ENUM_UNKNOWN_SARIF = "unknown"

  @@strict_enums = false

  # When `true`, deserializing an enum string outside the known SARIF 2.1.0 set
  # raises `Sarif::Error`. When `false` (the default), such values are tolerated
  # and map to the enum's `Unknown` sentinel member so a single unrecognized
  # value never aborts an entire document parse.
  #
  # Real-world producers and forward/backward compatibility (SARIF v2.2 values,
  # vendor extensions) routinely emit values this library does not know about;
  # the tolerant default keeps the rest of the log parseable.
  #
  # ```
  # Sarif.strict_enums = true # opt into strict (raising) deserialization
  # ```
  def self.strict_enums : Bool
    @@strict_enums
  end

  def self.strict_enums=(value : Bool) : Bool
    @@strict_enums = value
  end

  # Runs the given block with strict enum parsing enabled, restoring the
  # previous setting afterwards (even if the block raises).
  def self.with_strict_enums(& : -> T) : T forall T
    previous = @@strict_enums
    @@strict_enums = true
    begin
      yield
    ensure
      @@strict_enums = previous
    end
  end

  # Macro for defining SARIF enums with bidirectional JSON serialization.
  # Maps Crystal enum values to their camelCase SARIF string representations.
  #
  # Every generated enum also gains an `Unknown` sentinel member. When
  # `Sarif.strict_enums` is `false` (the default), a string outside the known
  # set deserializes to `Unknown` instead of raising, so one unrecognized value
  # cannot abort a whole document parse. With `Sarif.strict_enums = true` the
  # known-only behavior is restored and `Sarif::Error` is raised instead.
  macro sarif_enum(name, mapping)
    enum {{ name }}
      {% for key, _value in mapping %}
        {{ key }}
      {% end %}

      # Sentinel for values outside the known SARIF 2.1.0 set. Used by the
      # tolerant deserialization path; serializes to `Sarif::ENUM_UNKNOWN_SARIF`.
      Unknown

      def to_json(json : JSON::Builder) : Nil
        json.string(to_s_sarif)
      end

      def to_s_sarif : String
        case self
        {% for key, value in mapping %}
        when {{ key }} then {{ value }}
        {% end %}
        when Unknown then ::Sarif::ENUM_UNKNOWN_SARIF
        else
          raise ::Sarif::Error.new("Unknown #{self.class} value: #{self}")
        end
      end

      # Resolves a SARIF string to an enum member. Returns `nil` when the value
      # is not part of the known set, leaving the strict-vs-tolerant policy to
      # the caller.
      def self.from_sarif?(str : String) : self?
        case str
        {% for key, value in mapping %}
        when {{ value }} then {{ key }}
        {% end %}
        when ::Sarif::ENUM_UNKNOWN_SARIF then Unknown
        else
          nil
        end
      end

      # Resolves a SARIF string to an enum member, honoring `Sarif.strict_enums`:
      # in strict mode an unknown value raises `Sarif::Error`; otherwise it maps
      # to the `Unknown` sentinel.
      private def self.resolve_sarif(str : String) : self
        if member = from_sarif?(str)
          member
        elsif ::Sarif.strict_enums
          raise ::Sarif::Error.new("Unknown #{self} value: #{str}")
        else
          Unknown
        end
      end

      # Entry point used by `JSON::Serializable` for enum-typed fields during
      # full-document parsing. Tolerant by default; raises in strict mode.
      def self.new(pull : JSON::PullParser) : self
        resolve_sarif(pull.read_string)
      end

      def self.from_json(pull : JSON::PullParser) : self
        resolve_sarif(pull.read_string)
      end

      def self.parse_sarif(str : String) : self
        resolve_sarif(str)
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
