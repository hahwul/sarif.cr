require "json"

module Sarif
  class ResultProvenance
    include JSON::Serializable

    @[JSON::Field(key: "firstDetectionTimeUtc")]
    property first_detection_time_utc : String? = nil

    @[JSON::Field(key: "lastDetectionTimeUtc")]
    property last_detection_time_utc : String? = nil

    @[JSON::Field(key: "firstDetectionRunGuid")]
    property first_detection_run_guid : String? = nil

    @[JSON::Field(key: "lastDetectionRunGuid")]
    property last_detection_run_guid : String? = nil

    @[JSON::Field(key: "invocationIndex")]
    property invocation_index : Int32? = nil

    @[JSON::Field(key: "conversionSources")]
    property conversion_sources : Array(PhysicalLocation)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@first_detection_time_utc : String? = nil,
                   @last_detection_time_utc : String? = nil,
                   @first_detection_run_guid : String? = nil,
                   @last_detection_run_guid : String? = nil,
                   @invocation_index : Int32? = nil,
                   @conversion_sources : Array(PhysicalLocation)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
