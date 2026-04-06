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
