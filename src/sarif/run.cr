require "json"

module Sarif
  # A single invocation of a single analysis tool on a single artifact or set of artifacts.
  #
  # A `Run` contains the tool description, results, artifacts analyzed, and invocation details.
  #
  # See: [SARIF 2.1.0 §3.14](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317484)
  class Run
    include JSON::Serializable

    property tool : Tool

    property results : Array(Result)? = nil

    property artifacts : Array(Artifact)? = nil

    property invocations : Array(Invocation)? = nil

    @[JSON::Field(key: "logicalLocations")]
    property logical_locations : Array(LogicalLocation)? = nil

    property graphs : Array(Graph)? = nil

    property conversion : Conversion? = nil

    property language : String? = nil

    @[JSON::Field(key: "redactionTokens")]
    property redaction_tokens : Array(String)? = nil

    @[JSON::Field(key: "defaultEncoding")]
    property default_encoding : String? = nil

    @[JSON::Field(key: "defaultSourceLanguage")]
    property default_source_language : String? = nil

    @[JSON::Field(key: "newlineSequences")]
    property newline_sequences : Array(String)? = nil

    @[JSON::Field(key: "columnKind")]
    property column_kind : ColumnKind? = nil

    @[JSON::Field(key: "automationDetails")]
    property automation_details : RunAutomationDetails? = nil

    @[JSON::Field(key: "runAggregates")]
    property run_aggregates : Array(RunAutomationDetails)? = nil

    @[JSON::Field(key: "baselineGuid")]
    property baseline_guid : String? = nil

    @[JSON::Field(key: "externalPropertyFileReferences")]
    property external_property_file_references : ExternalPropertyFileReferences? = nil

    @[JSON::Field(key: "threadFlowLocations")]
    property thread_flow_locations : Array(ThreadFlowLocation)? = nil

    property taxonomies : Array(ToolComponent)? = nil

    property addresses : Array(Address)? = nil

    property translations : Array(ToolComponent)? = nil

    property policies : Array(ToolComponent)? = nil

    @[JSON::Field(key: "webRequests")]
    property web_requests : Array(WebRequest)? = nil

    @[JSON::Field(key: "webResponses")]
    property web_responses : Array(WebResponse)? = nil

    @[JSON::Field(key: "specialLocations")]
    property special_locations : SpecialLocations? = nil

    @[JSON::Field(key: "versionControlProvenance")]
    property version_control_provenance : Array(VersionControlDetails)? = nil

    @[JSON::Field(key: "originalUriBaseIds")]
    property original_uri_base_ids : Hash(String, ArtifactLocation)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@tool : Tool, @results : Array(Result)? = nil,
                   @artifacts : Array(Artifact)? = nil,
                   @invocations : Array(Invocation)? = nil,
                   @logical_locations : Array(LogicalLocation)? = nil,
                   @graphs : Array(Graph)? = nil, @conversion : Conversion? = nil,
                   @language : String? = nil, @redaction_tokens : Array(String)? = nil,
                   @default_encoding : String? = nil,
                   @default_source_language : String? = nil,
                   @newline_sequences : Array(String)? = nil,
                   @column_kind : ColumnKind? = nil,
                   @automation_details : RunAutomationDetails? = nil,
                   @run_aggregates : Array(RunAutomationDetails)? = nil,
                   @baseline_guid : String? = nil,
                   @external_property_file_references : ExternalPropertyFileReferences? = nil,
                   @thread_flow_locations : Array(ThreadFlowLocation)? = nil,
                   @taxonomies : Array(ToolComponent)? = nil,
                   @addresses : Array(Address)? = nil,
                   @translations : Array(ToolComponent)? = nil,
                   @policies : Array(ToolComponent)? = nil,
                   @web_requests : Array(WebRequest)? = nil,
                   @web_responses : Array(WebResponse)? = nil,
                   @special_locations : SpecialLocations? = nil,
                   @version_control_provenance : Array(VersionControlDetails)? = nil,
                   @original_uri_base_ids : Hash(String, ArtifactLocation)? = nil,
                   @properties : PropertyBag? = nil)
    end

    def results_by_rule_id(rule_id : String) : Array(Result)
      return [] of Result unless rs = results
      rs.select { |r| r.rule_id == rule_id }
    end

    def results_by_level(level : Level) : Array(Result)
      return [] of Result unless rs = results
      rs.select { |r| r.effective_level == level }
    end

    def find_results(rule_id : String? = nil, level : Level? = nil,
                     kind : ResultKind? = nil) : Array(Result)
      return [] of Result unless rs = results
      rs.select do |r|
        next false if rule_id && r.rule_id != rule_id
        next false if level && r.effective_level != level
        next false if kind && r.effective_kind != kind
        true
      end
    end

    def result_counts_by_level : Hash(Level, Int32)
      counts = {} of Level => Int32
      return counts unless rs = results
      rs.each do |r|
        lvl = r.effective_level
        counts[lvl] = (counts[lvl]? || 0) + 1
      end
      counts
    end

    def result_counts_by_rule_id : Hash(String, Int32)
      counts = {} of String => Int32
      return counts unless rs = results
      rs.each do |r|
        if rid = r.rule_id
          counts[rid] = (counts[rid]? || 0) + 1
        end
      end
      counts
    end

    def rule_by_id(rule_id : String) : ReportingDescriptor?
      tool.driver.rules.try &.find { |r| r.id == rule_id }
    end

    def valid? : Bool
      return false if tool.driver.name.empty?
      results.try &.each do |result|
        return false unless result.valid?
      end
      true
    end
  end
end
