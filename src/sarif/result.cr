require "json"

module Sarif
  # A single result (finding) from a static analysis tool.
  #
  # Each result must have a `message` with either text or an id.
  # Optionally references a rule via `rule_id` and/or `rule_index`.
  #
  # See: [SARIF 2.1.0 §3.27](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317638)
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

    # Computes the effective severity level per the SARIF 2.1.0 §3.27.10
    # default-level algorithm.
    #
    # - If `level` is set explicitly, it is returned.
    # - Else, if `kind` is present and not `fail` (pass/notApplicable/review/
    #   open/informational), the effective level is `none`.
    # - Else (kind is `fail` or absent) the level is taken from the associated
    #   rule's configuration when a `run` is supplied and the rule is
    #   resolvable: a matching `configurationOverride` reachable through
    #   `provenance.invocationIndex` wins over the rule's
    #   `defaultConfiguration.level`.
    # - Else it falls back to `warning`.
    #
    # See: [SARIF 2.1.0 §3.27.10](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317648)
    #
    # NOTE: the pseudocode in §3.27.10 attaches its `ELSE` branch to the
    # `invocationIndex >= 0` test, which would discard the rule's
    # `defaultConfiguration.level` whenever provenance names an invocation that
    # happens to carry no override for the rule. That reading makes an unrelated
    # provenance annotation silently downgrade a configured `error` to
    # `warning`, so the override is applied as an override here: it takes
    # precedence when present, and `defaultConfiguration.level` still applies
    # when it is not.
    #
    # The `run` argument is optional for backward compatibility: when omitted,
    # the kind-based part of the algorithm still applies and the method falls
    # back to `warning` whenever a rule cannot be resolved.
    def effective_level(run : Run? = nil) : Level
      if lvl = level
        return lvl
      end

      if (k = kind) && k != ResultKind::Fail
        return Level::None
      end

      if run && (descriptor = resolve_rule(run))
        if override_level = resolve_override_level(run, descriptor)
          return override_level
        end
        if (config = descriptor.default_configuration) && (rule_level = config.level)
          return rule_level
        end
      end

      Level::Warning
    end

    # Resolves the `ReportingDescriptor` associated with this result.
    #
    # The lookup reference is `rule`, with its absent `id`/`index` defaulting to
    # this result's `ruleId`/`ruleIndex`; with no `rule`, it is `{id: ruleId,
    # index: ruleIndex}` (§3.27.7). It is resolved by `toolComponent`, `index`
    # and `guid` as `Run#resolve_rule_reference` describes (§3.52.3). An index
    # of `-1` is the "no descriptor" sentinel and never resolves.
    #
    # When that finds nothing (no usable `index` or `guid`, or one that
    # dangles), the rule is looked up by the reference's id in the referenced
    # component; see `#lookup_rule`.
    #
    # See: [SARIF 2.1.0 §3.27.7](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317645)
    def resolve_rule(run : Run) : ReportingDescriptor?
      lookup_rule(run, ReportingDescriptorReference.new(
        id: rule.try(&.id) || rule_id,
        index: rule.try(&.index) || rule_index,
        guid: rule.try(&.guid),
        tool_component: rule.try(&.tool_component)
      ))
    end

    # `Run#resolve_rule_reference` (§3.52.3: `index`, then `guid`), else the
    # rule in the referenced component whose id `reference.id` names (exact id
    # first, then the hierarchical form, see `ToolComponent#find_rule`).
    #
    # The id step is a consumer convenience, not part of the §3.52.3 lookup,
    # where `id` does not participate (§3.52.4 NOTE). It is kept because
    # `ruleId`'s leading components are the rule's stable id (§3.27.5,
    # §3.49.3), many producers emit only `ruleId` (the case §3.27.7 NOTE 2
    # describes), and producers such as the sarif-sdk write configuration
    # overrides whose `descriptor` carries only an `id`.
    private def lookup_rule(run : Run, reference : ReportingDescriptorReference) : ReportingDescriptor?
      if descriptor = run.resolve_rule_reference(reference)
        return descriptor
      end
      return unless rid = reference.id
      run.tool_component_for(reference.tool_component).try &.find_rule(rid)
    end

    # Returns the level set by the `configurationOverride` that this result's
    # `provenance.invocationIndex` points at, or nil when there is none.
    #
    # See: [SARIF 2.1.0 §3.20.5](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317566)
    private def resolve_override_level(run : Run, descriptor : ReportingDescriptor) : Level?
      idx = provenance.try &.invocation_index
      return unless idx && idx >= 0

      invocation = run.invocations.try &.[idx]?
      return unless invocation

      overrides = invocation.rule_configuration_overrides
      return unless overrides

      overrides.each do |override|
        next unless lookup_rule(run, override.descriptor).try &.same?(descriptor)
        if lvl = override.configuration.level
          return lvl
        end
      end

      nil
    end

    # The rule id this result reports: `ruleId`, or else `rule.id`.
    #
    # A direct producer SHALL emit at least one of the two, and when both are
    # present they are equal (§3.27.5), so a result that carries only
    # `rule.id` still names its rule.
    #
    # See: [SARIF 2.1.0 §3.27.5](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317643)
    def effective_rule_id : String?
      rule_id || rule.try(&.id)
    end

    def effective_kind : ResultKind
      kind || ResultKind::Fail
    end

    def valid? : Bool
      return false unless message.valid?
      if (r = rank) && !Sarif.valid_rank?(r)
        return false
      end
      if (c = occurrence_count) && c < 1
        return false
      end
      true
    end
  end
end
