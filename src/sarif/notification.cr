require "json"

module Sarif
  class Notification
    include JSON::Serializable

    property message : Message

    property level : NotificationLevel? = nil

    property locations : Array(Location)? = nil

    @[JSON::Field(key: "timeUtc")]
    property time_utc : String? = nil

    @[JSON::Field(key: "exception")]
    property sarif_exception : SarifException? = nil

    property descriptor : ReportingDescriptorReference? = nil

    @[JSON::Field(key: "associatedRule")]
    property associated_rule : ReportingDescriptorReference? = nil

    @[JSON::Field(key: "threadId")]
    property thread_id : Int32? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@message : Message, @level : NotificationLevel? = nil,
                   @locations : Array(Location)? = nil, @time_utc : String? = nil,
                   @sarif_exception : SarifException? = nil,
                   @descriptor : ReportingDescriptorReference? = nil,
                   @associated_rule : ReportingDescriptorReference? = nil,
                   @thread_id : Int32? = nil, @properties : PropertyBag? = nil)
    end
  end
end
