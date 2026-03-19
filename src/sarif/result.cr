require "json"

module Sarif
  class Result
    include JSON::Serializable

    property message : Message

    @[JSON::Field(key: "ruleId")]
    property rule_id : String? = nil

    @[JSON::Field(key: "ruleIndex")]
    property rule_index : Int32? = nil

    property rule : ReportingDescriptorReference? = nil

    property kind : ResultKind? = nil

    property level : Level? = nil

    @[JSON::Field(key: "analysisTarget")]
    property analysis_target : ArtifactLocation? = nil

    property locations : Array(Location)? = nil

    property guid : String? = nil

    @[JSON::Field(key: "correlationGuid")]
    property correlation_guid : String? = nil

    @[JSON::Field(key: "occurrenceCount")]
    property occurrence_count : Int32? = nil

    @[JSON::Field(key: "partialFingerprints")]
    property partial_fingerprints : Hash(String, String)? = nil

    property fingerprints : Hash(String, String)? = nil

    property stacks : Array(Stack)? = nil

    @[JSON::Field(key: "codeFlows")]
    property code_flows : Array(CodeFlow)? = nil

    property graphs : Array(Graph)? = nil

    @[JSON::Field(key: "graphTraversals")]
    property graph_traversals : Array(GraphTraversal)? = nil

    @[JSON::Field(key: "relatedLocations")]
    property related_locations : Array(Location)? = nil

    property suppressions : Array(Suppression)? = nil

    @[JSON::Field(key: "baselineState")]
    property baseline_state : BaselineState? = nil

    property rank : Float64? = nil

    property attachments : Array(Attachment)? = nil

    @[JSON::Field(key: "workItemUris")]
    property work_item_uris : Array(String)? = nil

    property provenance : ResultProvenance? = nil

    property fixes : Array(Fix)? = nil

    property taxa : Array(ReportingDescriptorReference)? = nil

    @[JSON::Field(key: "webRequest")]
    property web_request : WebRequest? = nil

    @[JSON::Field(key: "webResponse")]
    property web_response : WebResponse? = nil

    @[JSON::Field(key: "hostedViewerUri")]
    property hosted_viewer_uri : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@message : Message, @rule_id : String? = nil,
                   @rule_index : Int32? = nil, @rule : ReportingDescriptorReference? = nil,
                   @kind : ResultKind? = nil, @level : Level? = nil,
                   @analysis_target : ArtifactLocation? = nil,
                   @locations : Array(Location)? = nil, @guid : String? = nil,
                   @correlation_guid : String? = nil, @occurrence_count : Int32? = nil,
                   @partial_fingerprints : Hash(String, String)? = nil,
                   @fingerprints : Hash(String, String)? = nil,
                   @stacks : Array(Stack)? = nil,
                   @code_flows : Array(CodeFlow)? = nil,
                   @graphs : Array(Graph)? = nil,
                   @graph_traversals : Array(GraphTraversal)? = nil,
                   @related_locations : Array(Location)? = nil,
                   @suppressions : Array(Suppression)? = nil,
                   @baseline_state : BaselineState? = nil,
                   @rank : Float64? = nil,
                   @attachments : Array(Attachment)? = nil,
                   @work_item_uris : Array(String)? = nil,
                   @provenance : ResultProvenance? = nil,
                   @fixes : Array(Fix)? = nil,
                   @taxa : Array(ReportingDescriptorReference)? = nil,
                   @web_request : WebRequest? = nil,
                   @web_response : WebResponse? = nil,
                   @hosted_viewer_uri : String? = nil,
                   @properties : PropertyBag? = nil)
    end

    def effective_level : Level
      level || Level::Warning
    end

    def effective_kind : ResultKind
      kind || ResultKind::Fail
    end

    def valid? : Bool
      return false unless message.valid?
      if (r = rank) && (r < 0.0 || r > 100.0)
        return false
      end
      if (c = occurrence_count) && c < 1
        return false
      end
      true
    end
  end
end
