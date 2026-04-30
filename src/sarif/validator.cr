module Sarif
  # Validates a `SarifLog` against SARIF 2.1.0 constraints.
  #
  # ```
  # result = Sarif::Validator.new.validate(log)
  # unless result.valid?
  #   result.errors.each { |e| puts e }
  # end
  # ```
  #
  # Supports optional limits to prevent resource exhaustion:
  # ```
  # validator = Sarif::Validator.new(max_runs: 10, max_results: 1000, max_depth: 50)
  # ```
  class Validator
    private GUID_PATTERN = Sarif::GUID_PATTERN
    private RFC3339_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/
    private URI_PATTERN     = /\A[a-zA-Z][a-zA-Z0-9+\-.]*:/

    getter max_results : Int32?
    getter max_runs : Int32?
    getter max_depth : Int32

    def initialize(@max_results : Int32? = nil, @max_runs : Int32? = nil, @max_depth : Int32 = 100)
    end

    def validate(log : SarifLog) : ValidationResult
      errors = [] of ValidationError

      validate_version(log, errors)
      validate_array_limit(log.runs, max_runs, "$.runs", "runs", errors)
      validate_runs(log, errors, depth: 1)

      ValidationResult.new(errors)
    end

    private def validate_version(log : SarifLog, errors : Array(ValidationError))
      unless log.version == SARIF_VERSION
        errors << ValidationError.new(
          "Unsupported SARIF version: #{log.version}. Expected #{SARIF_VERSION}",
          "$.version"
        )
      end
    end

    private def check_depth!(path : String, depth : Int32, errors : Array(ValidationError)) : Bool
      if depth > max_depth
        errors << ValidationError.new(
          "Validation depth #{depth} exceeds maximum allowed depth of #{max_depth}",
          path
        )
        return false
      end
      true
    end

    private def validate_runs(log : SarifLog, errors : Array(ValidationError), *, depth : Int32)
      log.runs.each_with_index do |run, i|
        validate_run(run, "$.runs[#{i}]", errors, depth: depth)
      end
    end

    private def validate_run(run : Run, path : String, errors : Array(ValidationError), *, depth : Int32)
      return unless check_depth!(path, depth, errors)

      validate_tool(run.tool, "#{path}.tool", errors)

      if results = run.results
        validate_array_limit(results, max_results, "#{path}.results", "results", errors)
      end

      run.results.try &.each_with_index do |result, j|
        validate_result(result, run, "#{path}.results[#{j}]", errors, depth: depth + 1)
      end

      # Validate index references in results
      artifact_count = run.artifacts.try(&.size) || 0
      logical_location_count = run.logical_locations.try(&.size) || 0

      run.results.try &.each_with_index do |result, j|
        result_path = "#{path}.results[#{j}]"
        validate_result_index_references(result, result_path, artifact_count, logical_location_count, errors)
      end

      run.invocations.try &.each_with_index do |inv, j|
        validate_invocation(inv, "#{path}.invocations[#{j}]", errors, depth: depth)
      end

      run.artifacts.try &.each_with_index do |artifact, j|
        validate_artifact(artifact, "#{path}.artifacts[#{j}]", j, artifact_count, errors)
      end

      run.version_control_provenance.try &.each_with_index do |vcd, j|
        validate_version_control_details(vcd, "#{path}.versionControlProvenance[#{j}]", errors)
      end

      run.graphs.try &.each_with_index do |graph, j|
        validate_graph(graph, "#{path}.graphs[#{j}]", errors)
      end

      if refs = run.external_property_file_references
        validate_external_property_file_references(refs, "#{path}.externalPropertyFileReferences", errors)
      end

      validate_guid(run.baseline_guid, "#{path}.baselineGuid", errors)
    end

    private def validate_tool(tool : Tool, path : String, errors : Array(ValidationError))
      validate_tool_component(tool.driver, "#{path}.driver", errors)

      tool.extensions.try &.each_with_index do |ext, i|
        validate_tool_component(ext, "#{path}.extensions[#{i}]", errors)
      end
    end

    private def validate_tool_component(component : ToolComponent, path : String, errors : Array(ValidationError))
      if component.name.empty?
        errors << ValidationError.new("Tool driver name must not be empty", "#{path}.name")
      end

      validate_guid(component.guid, "#{path}.guid", errors)
      validate_uri(component.download_uri, "#{path}.downloadUri", errors)
      validate_uri(component.information_uri, "#{path}.informationUri", errors)

      if rules = component.rules
        validate_descriptor_id_uniqueness(rules, "#{path}.rules", errors)
        rules.each_with_index do |rule, i|
          validate_reporting_descriptor(rule, "#{path}.rules[#{i}]", errors)
        end
      end

      if notifs = component.notifications
        validate_descriptor_id_uniqueness(notifs, "#{path}.notifications", errors)
        notifs.each_with_index do |notif, i|
          validate_reporting_descriptor(notif, "#{path}.notifications[#{i}]", errors)
        end
      end
    end

    private def validate_descriptor_id_uniqueness(descriptors : Array(ReportingDescriptor), path : String,
                                                   errors : Array(ValidationError))
      seen_ids = Set(String).new
      descriptors.each_with_index do |desc, i|
        next if desc.id.empty?
        if seen_ids.includes?(desc.id)
          errors << ValidationError.new(
            "duplicate descriptor id: '#{desc.id}'",
            "#{path}[#{i}].id"
          )
        else
          seen_ids << desc.id
        end
      end
    end

    private def validate_reporting_descriptor(descriptor : ReportingDescriptor, path : String, errors : Array(ValidationError))
      if descriptor.id.empty?
        errors << ValidationError.new("ReportingDescriptor id must not be empty", "#{path}.id")
      end

      validate_guid(descriptor.guid, "#{path}.guid", errors)
      validate_uri(descriptor.help_uri, "#{path}.helpUri", errors)

      if config = descriptor.default_configuration
        validate_reporting_configuration(config, "#{path}.defaultConfiguration", errors)
      end
    end

    private def validate_result(result : Result, run : Run, path : String,
                                errors : Array(ValidationError), *, depth : Int32)
      return unless check_depth!(path, depth, errors)

      if result.message.text.nil? && result.message.id.nil?
        errors << ValidationError.new(
          "Result message must have either text or id",
          "#{path}.message"
        )
      end

      if rule_index = result.rule_index
        rules = run.tool.driver.rules
        if rules.nil? || rule_index < 0 || rule_index >= rules.size
          errors << ValidationError.new(
            "Invalid ruleIndex: #{rule_index}",
            "#{path}.ruleIndex"
          )
        elsif (rule_id = result.rule_id) && rules[rule_index].id != rule_id
          errors << ValidationError.new(
            "ruleId '#{rule_id}' does not match rule at ruleIndex #{rule_index} ('#{rules[rule_index].id}')",
            "#{path}.ruleId"
          )
        end
      end

      validate_guid(result.guid, "#{path}.guid", errors)
      validate_guid(result.correlation_guid, "#{path}.correlationGuid", errors)

      if (rank = result.rank) && (rank < 0.0 || rank > 100.0)
        errors << ValidationError.new(
          "rank must be between 0.0 and 100.0, got #{rank}",
          "#{path}.rank"
        )
      end

      if (count = result.occurrence_count) && count < 1
        errors << ValidationError.new(
          "occurrenceCount must be >= 1, got #{count}",
          "#{path}.occurrenceCount"
        )
      end

      result.locations.try &.each_with_index do |loc, k|
        validate_location(loc, "#{path}.locations[#{k}]", errors)
      end

      result.related_locations.try &.each_with_index do |loc, k|
        validate_location(loc, "#{path}.relatedLocations[#{k}]", errors)
      end

      result.code_flows.try &.each_with_index do |cf, k|
        validate_code_flow(cf, "#{path}.codeFlows[#{k}]", errors)
      end

      result.graphs.try &.each_with_index do |graph, k|
        validate_graph(graph, "#{path}.graphs[#{k}]", errors)
      end

      result.graph_traversals.try &.each_with_index do |gt, k|
        validate_graph_traversal(gt, "#{path}.graphTraversals[#{k}]", errors)
      end

      result.stacks.try &.each_with_index do |stack, k|
        validate_stack(stack, "#{path}.stacks[#{k}]", errors)
      end

      result.fixes.try &.each_with_index do |fix, k|
        validate_fix(fix, "#{path}.fixes[#{k}]", errors)
      end

      if provenance = result.provenance
        validate_result_provenance(provenance, "#{path}.provenance", errors)
      end
    end

    private def validate_result_provenance(provenance : ResultProvenance, path : String,
                                            errors : Array(ValidationError))
      validate_timestamp(provenance.first_detection_time_utc, "#{path}.firstDetectionTimeUtc", errors)
      validate_timestamp(provenance.last_detection_time_utc, "#{path}.lastDetectionTimeUtc", errors)
      validate_guid(provenance.first_detection_run_guid, "#{path}.firstDetectionRunGuid", errors)
      validate_guid(provenance.last_detection_run_guid, "#{path}.lastDetectionRunGuid", errors)

      if (first = provenance.first_detection_time_utc) && (last = provenance.last_detection_time_utc)
        if first > last
          errors << ValidationError.new(
            "lastDetectionTimeUtc must not be before firstDetectionTimeUtc",
            "#{path}.lastDetectionTimeUtc"
          )
        end
      end
    end

    private def validate_exception(exception : SarifException, path : String,
                                    errors : Array(ValidationError), *, depth : Int32)
      return unless check_depth!(path, depth, errors)

      if ex_stack = exception.stack
        validate_stack(ex_stack, "#{path}.stack", errors)
      end

      exception.inner_exceptions.try &.each_with_index do |inner, i|
        validate_exception(inner, "#{path}.innerExceptions[#{i}]", errors, depth: depth + 1)
      end
    end

    private def validate_invocation(inv : Invocation, path : String,
                                    errors : Array(ValidationError), *, depth : Int32)
      validate_timestamp(inv.start_time_utc, "#{path}.startTimeUtc", errors)
      validate_timestamp(inv.end_time_utc, "#{path}.endTimeUtc", errors)

      if (start_time = inv.start_time_utc) && (end_time = inv.end_time_utc)
        if start_time > end_time
          errors << ValidationError.new(
            "endTimeUtc must not be before startTimeUtc",
            "#{path}.endTimeUtc"
          )
        end
      end

      inv.tool_execution_notifications.try &.each_with_index do |notif, i|
        if ex = notif.sarif_exception
          validate_exception(ex, "#{path}.toolExecutionNotifications[#{i}].exception", errors, depth: depth + 1)
        end
      end

      inv.tool_configuration_notifications.try &.each_with_index do |notif, i|
        if ex = notif.sarif_exception
          validate_exception(ex, "#{path}.toolConfigurationNotifications[#{i}].exception", errors, depth: depth + 1)
        end
      end
    end

    private def validate_artifact(artifact : Artifact, path : String,
                                   artifact_index : Int32, artifact_count : Int32,
                                   errors : Array(ValidationError))
      if (length = artifact.length) && length < -1
        errors << ValidationError.new(
          "artifact length must be >= -1, got #{length}",
          "#{path}.length"
        )
      end

      if (pi = artifact.parent_index) && artifact_count > 0 && (pi < 0 || pi >= artifact_count || pi == artifact_index)
        errors << ValidationError.new(
          "artifact parentIndex #{pi} is out of range (#{artifact_count} artifacts defined)",
          "#{path}.parentIndex"
        )
      end

      validate_timestamp(artifact.last_modified_time_utc, "#{path}.lastModifiedTimeUtc", errors)
    end

    private def validate_version_control_details(vcd : VersionControlDetails, path : String, errors : Array(ValidationError))
      if vcd.repository_uri.empty?
        errors << ValidationError.new(
          "repositoryUri must not be empty",
          "#{path}.repositoryUri"
        )
      end

      validate_timestamp(vcd.as_of_time_utc, "#{path}.asOfTimeUtc", errors)
    end

    private def validate_code_flow(code_flow : CodeFlow, path : String, errors : Array(ValidationError))
      if code_flow.thread_flows.empty?
        errors << ValidationError.new(
          "codeFlow must have at least one threadFlow",
          "#{path}.threadFlows"
        )
      end

      code_flow.thread_flows.each_with_index do |tf, i|
        if tf.locations.empty?
          errors << ValidationError.new(
            "threadFlow must have at least one location",
            "#{path}.threadFlows[#{i}].locations"
          )
        end
      end
    end

    private def validate_fix(fix : Fix, path : String, errors : Array(ValidationError))
      if fix.artifact_changes.empty?
        errors << ValidationError.new(
          "fix must have at least one artifactChange",
          "#{path}.artifactChanges"
        )
      end

      fix.artifact_changes.each_with_index do |change, i|
        if change.replacements.empty?
          errors << ValidationError.new(
            "artifactChange must have at least one replacement",
            "#{path}.artifactChanges[#{i}].replacements"
          )
        end
      end
    end

    private def validate_location(location : Location, path : String,
                                  errors : Array(ValidationError))
      if physical = location.physical_location
        validate_physical_location(physical, "#{path}.physicalLocation", errors)
      end
    end

    private def validate_physical_location(physical : PhysicalLocation, path : String,
                                           errors : Array(ValidationError))
      if physical.artifact_location.nil? && physical.address.nil?
        errors << ValidationError.new(
          "physicalLocation must have either artifactLocation or address",
          path
        )
      end

      if region = physical.region
        validate_region(region, "#{path}.region", errors)
      end
    end

    private def validate_region(region : Region, path : String,
                                errors : Array(ValidationError))
      if (sl = region.start_line) && sl < 1
        errors << ValidationError.new(
          "startLine must be >= 1, got #{sl}",
          "#{path}.startLine"
        )
      end

      if (sc = region.start_column) && sc < 1
        errors << ValidationError.new(
          "startColumn must be >= 1, got #{sc}",
          "#{path}.startColumn"
        )
      end

      if (el = region.end_line) && el < 1
        errors << ValidationError.new(
          "endLine must be >= 1, got #{el}",
          "#{path}.endLine"
        )
      end

      if (ec = region.end_column) && ec < 1
        errors << ValidationError.new(
          "endColumn must be >= 1, got #{ec}",
          "#{path}.endColumn"
        )
      end

      if (sl = region.start_line) && (el = region.end_line)
        if el < sl
          errors << ValidationError.new(
            "endLine (#{el}) must be >= startLine (#{sl})",
            "#{path}.endLine"
          )
        elsif el == sl
          if (sc = region.start_column) && (ec = region.end_column) && ec < sc
            errors << ValidationError.new(
              "endColumn (#{ec}) must be >= startColumn (#{sc}) on the same line",
              "#{path}.endColumn"
            )
          end
        end
      end
    end

    private def validate_guid(value : String?, path : String, errors : Array(ValidationError))
      return unless value
      unless GUID_PATTERN.matches?(value)
        errors << ValidationError.new(
          "Invalid GUID format: '#{value}'. Expected UUID format (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)",
          path
        )
      end
    end

    private def validate_timestamp(value : String?, path : String, errors : Array(ValidationError))
      return unless value
      unless RFC3339_PATTERN.matches?(value)
        errors << ValidationError.new(
          "Invalid timestamp format: '#{value}'. Expected RFC 3339 format (e.g., 2024-01-01T00:00:00Z)",
          path
        )
      end
    end

    private def validate_uri(value : String?, path : String, errors : Array(ValidationError))
      return unless value
      return if value.empty?
      unless URI_PATTERN.matches?(value)
        errors << ValidationError.new(
          "Invalid URI format: '#{value}'. Expected absolute URI with scheme",
          path
        )
      end
    end

    private def validate_graph_traversal(gt : GraphTraversal, path : String,
                                        errors : Array(ValidationError))
      if gt.run_graph_index.nil? && gt.result_graph_index.nil?
        errors << ValidationError.new(
          "graphTraversal must have either runGraphIndex or resultGraphIndex",
          path
        )
      end
    end

    private def validate_stack(stack : Stack, path : String,
                               errors : Array(ValidationError))
      if stack.frames.empty?
        errors << ValidationError.new(
          "stack must have at least one frame",
          "#{path}.frames"
        )
      end
    end

    private def validate_graph(graph : Graph, path : String,
                               errors : Array(ValidationError))
      node_ids = Set(String).new
      if nodes = graph.nodes
        nodes.each_with_index do |node, i|
          validate_node(node, "#{path}.nodes[#{i}]", node_ids, errors, depth: 1)
        end
      end

      if edges = graph.edges
        edge_ids = Set(String).new
        edges.each_with_index do |edge, i|
          validate_edge(edge, "#{path}.edges[#{i}]", edge_ids, node_ids, errors)
        end
      end
    end

    private def validate_node(node : Node, path : String, seen_ids : Set(String),
                              errors : Array(ValidationError), *, depth : Int32)
      # Bound recursion through node.children so a malformed SARIF graph
      # with arbitrarily deep child chains can't blow the call stack.
      return unless check_depth!(path, depth, errors)

      if node.id.empty?
        errors << ValidationError.new(
          "node id must not be empty",
          "#{path}.id"
        )
      elsif seen_ids.includes?(node.id)
        errors << ValidationError.new(
          "duplicate node id: '#{node.id}'",
          "#{path}.id"
        )
      else
        seen_ids << node.id
      end

      node.children.try &.each_with_index do |child, i|
        validate_node(child, "#{path}.children[#{i}]", seen_ids, errors, depth: depth + 1)
      end
    end

    private def validate_edge(edge : Edge, path : String, seen_ids : Set(String),
                              node_ids : Set(String), errors : Array(ValidationError))
      if edge.id.empty?
        errors << ValidationError.new(
          "edge id must not be empty",
          "#{path}.id"
        )
      elsif seen_ids.includes?(edge.id)
        errors << ValidationError.new(
          "duplicate edge id: '#{edge.id}'",
          "#{path}.id"
        )
      else
        seen_ids << edge.id
      end

      if edge.source_node_id.empty?
        errors << ValidationError.new(
          "edge sourceNodeId must not be empty",
          "#{path}.sourceNodeId"
        )
      elsif !node_ids.empty? && !node_ids.includes?(edge.source_node_id)
        errors << ValidationError.new(
          "edge sourceNodeId '#{edge.source_node_id}' references unknown node",
          "#{path}.sourceNodeId"
        )
      end

      if edge.target_node_id.empty?
        errors << ValidationError.new(
          "edge targetNodeId must not be empty",
          "#{path}.targetNodeId"
        )
      elsif !node_ids.empty? && !node_ids.includes?(edge.target_node_id)
        errors << ValidationError.new(
          "edge targetNodeId '#{edge.target_node_id}' references unknown node",
          "#{path}.targetNodeId"
        )
      end
    end

    private def validate_reporting_configuration(config : ReportingConfiguration, path : String,
                                                 errors : Array(ValidationError))
      if (rank = config.rank) && (rank < 0.0 || rank > 100.0)
        errors << ValidationError.new(
          "rank must be between 0.0 and 100.0, got #{rank}",
          "#{path}.rank"
        )
      end
    end

    private def validate_result_index_references(result : Result, path : String,
                                                 artifact_count : Int32, logical_location_count : Int32,
                                                 errors : Array(ValidationError))
      # Validate artifact index references in locations
      result.locations.try &.each_with_index do |loc, k|
        validate_location_index_references(loc, "#{path}.locations[#{k}]", artifact_count, logical_location_count, errors)
      end

      result.related_locations.try &.each_with_index do |loc, k|
        validate_location_index_references(loc, "#{path}.relatedLocations[#{k}]", artifact_count, logical_location_count, errors)
      end

      if target = result.analysis_target
        validate_artifact_location_index(target, "#{path}.analysisTarget", artifact_count, errors)
      end
    end

    private def validate_location_index_references(location : Location, path : String,
                                                    artifact_count : Int32, logical_location_count : Int32,
                                                    errors : Array(ValidationError))
      if physical = location.physical_location
        if artifact_loc = physical.artifact_location
          validate_artifact_location_index(artifact_loc, "#{path}.physicalLocation.artifactLocation", artifact_count, errors)
        end
      end

      location.logical_locations.try &.each_with_index do |ll, i|
        if (idx = ll.index) && idx >= 0 && logical_location_count > 0 && idx >= logical_location_count
          errors << ValidationError.new(
            "logicalLocation index #{idx} is out of range (#{logical_location_count} logical locations defined)",
            "#{path}.logicalLocations[#{i}].index"
          )
        end
      end
    end

    private def validate_artifact_location_index(artifact_loc : ArtifactLocation, path : String,
                                                  artifact_count : Int32, errors : Array(ValidationError))
      if (idx = artifact_loc.index) && idx >= 0 && artifact_count > 0 && idx >= artifact_count
        errors << ValidationError.new(
          "artifact index #{idx} is out of range (#{artifact_count} artifacts defined)",
          "#{path}.index"
        )
      end
    end

    private def validate_external_property_file_references(refs : ExternalPropertyFileReferences, path : String,
                                                           errors : Array(ValidationError))
      if ref = refs.conversion
        validate_external_property_file_reference(ref, "#{path}.conversion", errors)
      end
      refs.graphs.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.graphs[#{i}]", errors)
      end
      if ref = refs.externalized_properties
        validate_external_property_file_reference(ref, "#{path}.externalizedProperties", errors)
      end
      refs.artifacts.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.artifacts[#{i}]", errors)
      end
      refs.invocations.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.invocations[#{i}]", errors)
      end
      refs.logical_locations.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.logicalLocations[#{i}]", errors)
      end
      refs.thread_flow_locations.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.threadFlowLocations[#{i}]", errors)
      end
      refs.results.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.results[#{i}]", errors)
      end
      refs.taxonomies.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.taxonomies[#{i}]", errors)
      end
      refs.addresses.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.addresses[#{i}]", errors)
      end
      if ref = refs.driver
        validate_external_property_file_reference(ref, "#{path}.driver", errors)
      end
      refs.extensions.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.extensions[#{i}]", errors)
      end
      refs.policies.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.policies[#{i}]", errors)
      end
      refs.translations.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.translations[#{i}]", errors)
      end
      refs.web_requests.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.webRequests[#{i}]", errors)
      end
      refs.web_responses.try &.each_with_index do |ref, i|
        validate_external_property_file_reference(ref, "#{path}.webResponses[#{i}]", errors)
      end
    end

    private def validate_external_property_file_reference(ref : ExternalPropertyFileReference, path : String,
                                                          errors : Array(ValidationError))
      if ref.location.nil? && ref.guid.nil?
        errors << ValidationError.new(
          "externalPropertyFileReference must have either location or guid",
          path
        )
      end

      validate_guid(ref.guid, "#{path}.guid", errors)
    end

    private def validate_array_limit(array : Array, limit : Int32?, path : String,
                                     name : String, errors : Array(ValidationError))
      return unless max = limit
      if array.size > max
        errors << ValidationError.new(
          "#{name} array size #{array.size} exceeds maximum allowed size of #{max}",
          path
        )
      end
    end
  end
end
