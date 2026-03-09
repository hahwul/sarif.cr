require "json"

module Sarif
  class ConfigurationOverride
    include JSON::Serializable

    property configuration : ReportingConfiguration

    property descriptor : ReportingDescriptorReference

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@configuration : ReportingConfiguration,
                   @descriptor : ReportingDescriptorReference,
                   @properties : PropertyBag? = nil)
    end
  end
end
