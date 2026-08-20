require "json"

module Sarif
  class ReportingDescriptor
    include JSON::Serializable

    property id : String

    property name : String? = nil

    property guid : String? = nil

    @[JSON::Field(key: "deprecatedIds")]
    property deprecated_ids : Array(String)? = nil

    @[JSON::Field(key: "deprecatedNames")]
    property deprecated_names : Array(String)? = nil

    @[JSON::Field(key: "deprecatedGuids")]
    property deprecated_guids : Array(String)? = nil

    @[JSON::Field(key: "shortDescription")]
    property short_description : MultiformatMessageString? = nil

    @[JSON::Field(key: "fullDescription")]
    property full_description : MultiformatMessageString? = nil

    @[JSON::Field(key: "messageStrings")]
    property message_strings : Hash(String, MultiformatMessageString)? = nil

    @[JSON::Field(key: "defaultConfiguration")]
    property default_configuration : ReportingConfiguration? = nil

    @[JSON::Field(key: "helpUri")]
    property help_uri : String? = nil

    property help : MultiformatMessageString? = nil

    property relationships : Array(ReportingDescriptorRelationship)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@id : String, @name : String? = nil, @guid : String? = nil,
                   @short_description : MultiformatMessageString? = nil,
                   @full_description : MultiformatMessageString? = nil,
                   @message_strings : Hash(String, MultiformatMessageString)? = nil,
                   @default_configuration : ReportingConfiguration? = nil,
                   @help_uri : String? = nil, @help : MultiformatMessageString? = nil,
                   @relationships : Array(ReportingDescriptorRelationship)? = nil,
                   @deprecated_ids : Array(String)? = nil,
                   @deprecated_names : Array(String)? = nil,
                   @deprecated_guids : Array(String)? = nil,
                   @properties : PropertyBag? = nil)
    end

    # Returns true when `reference_id` identifies this descriptor.
    #
    # A `result.ruleId` or `reportingDescriptorReference.id` either equals the
    # descriptor's `id` or equals it plus exactly one additional hierarchical
    # component, where components are separated by `/`. For example, the rule
    # `"CA5350"` is identified by both `"CA5350"` and `"CA5350/md5"`.
    #
    # See: [SARIF 2.1.0 §3.52.4](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317871)
    # and [§3.5.4.1](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317425)
    def matches_id?(reference_id : String) : Bool
      return true if reference_id == id
      return false if id.empty?
      return false unless reference_id.starts_with?("#{id}/")
      suffix = reference_id[(id.size + 1)..]
      !suffix.empty? && !suffix.includes?('/')
    end

    def valid? : Bool
      return false if id.empty?
      if (g = guid) && !g.matches?(GUID_PATTERN)
        return false
      end
      if (config = default_configuration) && (rank = config.rank) && (rank < 0.0 || rank > 100.0)
        return false
      end
      true
    end
  end
end
