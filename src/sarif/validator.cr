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
    private GUID_PATTERN      = Sarif::GUID_PATTERN
    private TIMESTAMP_PATTERN = /\A(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2})(?::(\d{2})(?:\.(\d+))?)?(Z|[+-]\d{2}:\d{2}))?\z/
    private URI_PATTERN       = /\A[a-zA-Z][a-zA-Z0-9+\-.]*:/

    # The sentinel every index-valued property in the SARIF 2.1.0 schema uses
    # for "no referent": `ruleIndex`, `parentIndex`, `artifactLocation.index`
    # and friends are all declared `"default": -1, "minimum": -1`, so -1 is a
    # legal value that resolves to nothing, and only values below it are
    # out of range.
    private NO_INDEX = -1

    # Location IDs are shared across the objects belonging to one result.
    # Resolve relationships after visiting those locations (§3.28.2, §3.34.2).
    private class ResultLocationReferences
      @ids = Set(Int32).new
      @targets = [] of Tuple(Int32, String)
      @cached_indexes = Set(Int32).new

      property complete = true

      def initialize(@run_path : String)
      end

      def add(location : Location, path : String, errors : Array(ValidationError))
        if (id = location.id) && id >= 0 && !@ids.add?(id)
          errors << ValidationError.new("Duplicate location id #{id} in this result", "#{path}.id")
        end

        location.relationships.try &.each_with_index do |relationship, i|
          target = relationship.target
          next if target < 0
          target_path = "#{path}.relationships[#{i}].target"
          if target == location.id
            errors << ValidationError.new("Location relationship must target a different location", target_path)
          else
            @targets << {target, target_path}
          end
        end
      end

      def add_cached(index : Int32, cached : ThreadFlowLocation, errors : Array(ValidationError))
        # A result can visit the same cached location multiple times.
        return unless @cached_indexes.add?(index)
        path = "#{@run_path}.threadFlowLocations[#{index}]"
        if location = cached.location
          add(location, "#{path}.location", errors)
        end
        cached.stack.try(&.frames).try &.each_with_index do |frame, i|
          if location = frame.location
            add(location, "#{path}.stack.frames[#{i}].location", errors)
          end
        end
      end

      def validate_targets(errors : Array(ValidationError))
        return unless complete
        @targets.each do |target, path|
          unless @ids.includes?(target)
            errors << ValidationError.new("No location with id #{target} in this result", path)
          end
        end
      end
    end

    getter max_results : Int32?
    getter max_runs : Int32?
    getter max_depth : Int32

    def initialize(@max_results : Int32? = nil, @max_runs : Int32? = nil, @max_depth : Int32 = 100)
    end

    def validate(log : SarifLog) : ValidationResult
      errors = [] of ValidationError

      validate_version(log, errors)
      validate_uri(log.schema, "$.$schema", errors)
      log.inline_external_properties.try &.each_with_index do |external, i|
        path = "$.inlineExternalProperties[#{i}]"
        validate_guid(external.guid, "#{path}.guid", errors)
        validate_guid(external.run_guid, "#{path}.runGuid", errors)
        validate_uri(external.schema, "#{path}.$schema", errors)
        if (version = external.version) && version != log.version
          errors << ValidationError.new("External properties version must match the log version", "#{path}.version")
        end
      end
      if runs = log.runs
        validate_array_limit(runs, max_runs, "$.runs", "runs", errors)
      end
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
      log.runs.try &.each_with_index do |run, i|
        validate_run(run, "$.runs[#{i}]", errors, depth: depth)
      end
    end

    private def validate_run(run : Run, path : String, errors : Array(ValidationError), *, depth : Int32)
      return unless check_depth!(path, depth, errors)

      validate_tool(run.tool, run, "#{path}.tool", errors,
        allow_external_driver: !run.external_property_file_references.try(&.driver).nil?)
      {% for field in %w(taxonomies translations policies) %}
        run.{{field.id}}.try &.each_with_index do |component, i|
          validate_tool_component(component, run, "#{path}.{{field.id}}[#{i}]", errors)
        end
      {% end %}
      if sequences = run.newline_sequences
        if sequences.empty?
          errors << ValidationError.new("newlineSequences must contain at least one sequence", "#{path}.newlineSequences")
        end
        validate_unique_values(sequences, "#{path}.newlineSequences", errors)
      end
      validate_unique_values(run.redaction_tokens, "#{path}.redactionTokens", errors)

      if conversion = run.conversion
        validate_tool(conversion.tool, run, "#{path}.conversion.tool", errors)
        if invocation = conversion.invocation
          converter_run = run.dup
          converter_run.tool = conversion.tool
          # Only the analysis tool can externalize its driver and extensions.
          if refs = run.external_property_file_references.try(&.dup)
            refs.driver = nil
            refs.extensions = nil
            converter_run.external_property_file_references = refs
          end
          validate_invocation(invocation, converter_run, "#{path}.conversion.invocation", errors, depth: depth)
        end
        conversion.analysis_tool_log_files.try &.each_with_index do |location, i|
          validate_artifact_location(location, run, "#{path}.conversion.analysisToolLogFiles[#{i}]", errors)
        end
      end
      validate_artifact_location(run.special_locations.try(&.display_base), run, "#{path}.specialLocations.displayBase", errors)

      if results = run.results
        validate_array_limit(results, max_results, "#{path}.results", "results", errors)
      end

      refs = run.external_property_file_references

      graph_edge_ids = {} of Graph => Set(String)
      run.results.try &.each_with_index do |result, j|
        result_path = "#{path}.results[#{j}]"
        validate_result(result, run, result_path, errors, graph_edge_ids, run_path: path, depth: depth + 1)
      end

      validate_enum(run.column_kind, "#{path}.columnKind", errors)

      run.invocations.try &.each_with_index do |inv, j|
        validate_invocation(inv, run, "#{path}.invocations[#{j}]", errors, depth: depth)
      end

      run.artifacts.try &.each_with_index do |artifact, j|
        validate_artifact(artifact, run, "#{path}.artifacts[#{j}]", j, errors)
      end

      run.version_control_provenance.try &.each_with_index do |vcd, j|
        validate_version_control_details(vcd, run, "#{path}.versionControlProvenance[#{j}]", errors)
      end

      run.graphs.try &.each_with_index do |graph, j|
        validate_graph(graph, run, "#{path}.graphs[#{j}]", errors)
      end

      run.thread_flow_locations.try &.each_with_index do |tfl, j|
        validate_thread_flow_location(tfl, run, "#{path}.threadFlowLocations[#{j}]", errors)
      end

      run.addresses.try &.each_with_index do |address, j|
        validate_address(address, "#{path}.addresses[#{j}]", errors)
      end
      run.logical_locations.try &.each_with_index do |location, j|
        validate_logical_location(location, "#{path}.logicalLocations[#{j}]", errors)
      end
      run.web_requests.try &.each_with_index do |request, j|
        validate_min(request.index, NO_INDEX, "#{path}.webRequests[#{j}].index", "index", errors)
      end
      run.web_responses.try &.each_with_index do |response, j|
        validate_min(response.index, NO_INDEX, "#{path}.webResponses[#{j}].index", "index", errors)
      end

      if refs
        validate_external_property_file_references(refs, run, "#{path}.externalPropertyFileReferences", errors)
      end

      validate_guid(run.baseline_guid, "#{path}.baselineGuid", errors)

      if base_ids = run.original_uri_base_ids
        validate_original_uri_base_ids(base_ids, run, "#{path}.originalUriBaseIds", errors)
      end

      if details = run.automation_details
        validate_automation_details(details, "#{path}.automationDetails", errors)
      end
      run.run_aggregates.try &.each_with_index do |aggregate, j|
        validate_automation_details(aggregate, "#{path}.runAggregates[#{j}]", errors)
      end
    end

    private def validate_automation_details(details : RunAutomationDetails, path : String,
                                            errors : Array(ValidationError))
      validate_message(details.description, "#{path}.description", errors)
      validate_guid(details.guid, "#{path}.guid", errors)
      validate_guid(details.correlation_guid, "#{path}.correlationGuid", errors)
    end

    private def validate_tool(tool : Tool, run : Run, path : String, errors : Array(ValidationError), *, allow_external_driver : Bool = false)
      if driver = tool.driver?
        validate_tool_component(driver, run, "#{path}.driver", errors)
      elsif !allow_external_driver
        errors << ValidationError.new("Tool driver must be present", "#{path}.driver")
      end

      tool.extensions.try &.each_with_index do |ext, i|
        validate_tool_component(ext, run, "#{path}.extensions[#{i}]", errors)
      end
    end

    private def validate_tool_component(component : ToolComponent, run : Run, path : String, errors : Array(ValidationError))
      if component.name.empty?
        errors << ValidationError.new("Tool driver name must not be empty", "#{path}.name")
      end

      validate_guid(component.guid, "#{path}.guid", errors)
      validate_uri(component.download_uri, "#{path}.downloadUri", errors)
      validate_uri(component.information_uri, "#{path}.informationUri", errors)
      validate_timestamp(component.release_date_utc, "#{path}.releaseDateUtc", errors)
      validate_tool_component_reference(component.associated_component, "#{path}.associatedComponent", errors)

      component.supported_taxonomies.try &.each_with_index do |taxonomy, i|
        validate_tool_component_reference(taxonomy, "#{path}.supportedTaxonomies[#{i}]", errors)
      end
      component.locations.try &.each_with_index do |location, i|
        validate_artifact_location(location, run, "#{path}.locations[#{i}]", errors)
      end
      if metadata = component.translation_metadata
        validate_uri(metadata.download_uri, "#{path}.translationMetadata.downloadUri", errors)
        validate_uri(metadata.information_uri, "#{path}.translationMetadata.informationUri", errors)
      end

      validate_unique_values(component.contents, "#{path}.contents", errors)
      component.contents.try &.each_with_index do |content, i|
        validate_enum(content, "#{path}.contents[#{i}]", errors)
      end

      # Descriptor ids need not be unique within rules or notifications
      # (§3.19.23, §3.19.24); `index` disambiguates them.
      if rules = component.rules
        rules.each_with_index do |rule, i|
          validate_reporting_descriptor(rule, "#{path}.rules[#{i}]", errors)
        end
      end

      if notifs = component.notifications
        notifs.each_with_index do |notif, i|
          validate_reporting_descriptor(notif, "#{path}.notifications[#{i}]", errors)
        end
      end

      component.taxa.try &.each_with_index do |taxon, i|
        validate_reporting_descriptor(taxon, "#{path}.taxa[#{i}]", errors)
      end
    end

    private def validate_reporting_descriptor(descriptor : ReportingDescriptor, path : String, errors : Array(ValidationError))
      if descriptor.id.empty?
        errors << ValidationError.new("ReportingDescriptor id must not be empty", "#{path}.id")
      end

      validate_guid(descriptor.guid, "#{path}.guid", errors)
      descriptor.deprecated_guids.try &.each_with_index do |guid, i|
        validate_guid(guid, "#{path}.deprecatedGuids[#{i}]", errors)
      end
      validate_uri(descriptor.help_uri, "#{path}.helpUri", errors)

      if config = descriptor.default_configuration
        validate_reporting_configuration(config, "#{path}.defaultConfiguration", errors)
      end

      descriptor.relationships.try &.each_with_index do |relationship, i|
        validate_descriptor_reference(relationship.target, "#{path}.relationships[#{i}].target", errors)
        validate_message(relationship.description, "#{path}.relationships[#{i}].description", errors)
      end
    end

    private def validate_result(result : Result, run : Run, path : String,
                                errors : Array(ValidationError), graph_edge_ids : Hash(Graph, Set(String)), *, run_path : String, depth : Int32)
      return unless check_depth!(path, depth, errors)

      validate_message(result.message, "#{path}.message", errors, label: "Result message") do |id|
        reference = result.rule.try(&.tool_component)
        component = run.tool_component_for(reference)
        next nil if tool_component_pending?(run, reference, component)
        result.resolve_rule(run).try(&.message_strings).try(&.[id]?) ||
          component.try(&.global_message_strings).try(&.[id]?)
      end

      validate_result_rule(result, run, path, errors)

      validate_enum(result.level, "#{path}.level", errors)
      validate_enum(result.kind, "#{path}.kind", errors)

      # §3.27.10: when kind is anything but "fail", level SHALL be "none".
      # Values outside the vocabulary are reported by `validate_enum` above.
      kind, level = result.kind, result.level
      if kind && level && !kind.fail? && !kind.unknown? && !level.none? && !level.unknown?
        errors << ValidationError.new(
          "level must be 'none' when kind is '#{kind.to_s_sarif}', got '#{level.to_s_sarif}'",
          "#{path}.level"
        )
      end

      result.taxa.try &.each_with_index do |taxon, k|
        validate_descriptor_reference(taxon, "#{path}.taxa[#{k}]", errors)
      end

      validate_uri(result.hosted_viewer_uri, "#{path}.hostedViewerUri", errors)
      result.work_item_uris.try &.each_with_index do |uri, k|
        validate_uri(uri, "#{path}.workItemUris[#{k}]", errors)
      end
      validate_enum(result.baseline_state, "#{path}.baselineState", errors)

      validate_guid(result.guid, "#{path}.guid", errors)
      validate_guid(result.correlation_guid, "#{path}.correlationGuid", errors)
      validate_artifact_location(result.analysis_target, run, "#{path}.analysisTarget", errors)
      validate_min(result.web_request.try(&.index), NO_INDEX, "#{path}.webRequest.index", "index", errors)
      validate_min(result.web_response.try(&.index), NO_INDEX, "#{path}.webResponse.index", "index", errors)

      if (rank = result.rank) && !Sarif.valid_rank?(rank)
        errors << ValidationError.new(
          "rank must be between 0.0 and 100.0 (or -1.0 for unknown), got #{rank}",
          "#{path}.rank"
        )
      end

      if (count = result.occurrence_count) && count < 1
        errors << ValidationError.new(
          "occurrenceCount must be >= 1, got #{count}",
          "#{path}.occurrenceCount"
        )
      end

      references = ResultLocationReferences.new(run_path)
      result.locations.try &.each_with_index do |loc, k|
        validate_location(loc, run, "#{path}.locations[#{k}]", errors, references: references)
      end

      result.related_locations.try &.each_with_index do |loc, k|
        validate_location(loc, run, "#{path}.relatedLocations[#{k}]", errors, references: references)
      end

      result.code_flows.try &.each_with_index do |cf, k|
        validate_code_flow(cf, run, "#{path}.codeFlows[#{k}]", errors, references)
      end

      result.graphs.try &.each_with_index do |graph, k|
        validate_graph(graph, run, "#{path}.graphs[#{k}]", errors, references: references)
      end

      result.graph_traversals.try &.each_with_index do |gt, k|
        validate_graph_traversal(gt, run, result, "#{path}.graphTraversals[#{k}]", errors, graph_edge_ids)
      end

      result.stacks.try &.each_with_index do |stack, k|
        validate_stack(stack, run, "#{path}.stacks[#{k}]", errors, references: references)
      end

      result.fixes.try &.each_with_index do |fix, k|
        validate_fix(fix, run, "#{path}.fixes[#{k}]", errors)
      end

      result.attachments.try &.each_with_index do |attachment, k|
        attachment_path = "#{path}.attachments[#{k}]"
        validate_message(attachment.description, "#{attachment_path}.description", errors)
        validate_artifact_location(attachment.artifact_location, run, "#{attachment_path}.artifactLocation", errors)
        attachment.regions.try &.each_with_index do |region, i|
          validate_region(region, "#{attachment_path}.regions[#{i}]", errors)
        end
        attachment.rectangles.try &.each_with_index do |rectangle, i|
          validate_message(rectangle.message, "#{attachment_path}.rectangles[#{i}].message", errors)
        end
      end

      result.suppressions.try &.each_with_index do |suppression, k|
        validate_suppression(suppression, run, "#{path}.suppressions[#{k}]", errors, references)
      end
      references.validate_targets(errors)

      if provenance = result.provenance
        validate_result_provenance(provenance, run, "#{path}.provenance", errors)
      end
    end

    # Validates the rule reference triple `ruleIndex` / `ruleId` / `rule`.
    #
    # `ruleIndex` carries the `reportingDescriptorReference.index` semantics
    # (§3.27.6, §3.52.5): -1 means "no descriptor", so only a value below -1 is
    # malformed and only a non-negative value has to address an existing rule.
    # A `ruleId` identifies the descriptor it addresses when it equals the
    # descriptor's id or extends it by exactly one hierarchical component
    # (§3.27.5, §3.52.4). `rule.id` and `rule.index` default to `ruleId` and
    # `ruleIndex` respectively, and SHALL be equal when both are present
    # (§3.27.7). The descriptor lives in the component that `rule.toolComponent`
    # names, which defaults to the driver (§3.27.6, §3.52.3).
    private def validate_result_rule(result : Result, run : Run, path : String,
                                     errors : Array(ValidationError))
      reference = result.rule
      if reference
        # `ruleId` / `ruleIndex` supply `rule.id` / `rule.index` by default, so
        # a `rule` that only names its toolComponent is still identified.
        identified = !result.rule_id.nil? || !result.rule_index.nil?
        validate_descriptor_reference(reference, "#{path}.rule", errors, identified: identified)
      end
      validate_min(result.rule_index, NO_INDEX, "#{path}.ruleIndex", "ruleIndex", errors)
      validate_result_rule_descriptor(result, run, path, errors)
      validate_result_rule_consistency(reference, result, path, errors) if reference
    end

    private def validate_result_rule_descriptor(result : Result, run : Run, path : String, errors : Array(ValidationError))
      reference = result.rule
      component_reference = reference.try(&.tool_component)
      component = run.tool_component_for(component_reference)
      return if tool_component_pending?(run, component_reference, component)
      unless component
        errors << ValidationError.new(
          "rule.toolComponent does not identify a tool component of this run",
          "#{path}.rule.toolComponent"
        )
        return
      end
      rules = component.rules

      # `rule.index` defaults to `ruleIndex` (§3.27.7, §3.52.5), so the lookup
      # runs on whichever is given.
      index_label, rule_index = if idx = result.rule_index
                                  {"ruleIndex", idx}
                                else
                                  {"rule.index", reference.try(&.index)}
                                end

      guid = reference.try(&.guid)
      if rule_index && rule_index >= 0
        if descriptor = rules.try(&.[rule_index]?)
          if guid && GUID_PATTERN.matches?(guid) &&
             descriptor.guid.try(&.compare(guid, case_insensitive: true)) != 0
            errors << ValidationError.new(
              "rule.guid '#{guid}' does not match rule at #{index_label} #{rule_index} ('#{descriptor.id}')",
              "#{path}.rule.guid"
            )
          end
          validate_result_rule_ids(result, descriptor, "at #{index_label} #{rule_index}", path, errors)
        else
          errors << ValidationError.new(
            "Invalid #{index_label}: #{rule_index}",
            "#{path}.#{index_label}"
          )
        end
      elsif guid && GUID_PATTERN.matches?(guid)
        if descriptor = rules.try(&.find { |rule| rule.guid.try(&.compare(guid, case_insensitive: true)) == 0 })
          validate_result_rule_ids(result, descriptor, "with GUID #{guid}", path, errors)
        else
          errors << ValidationError.new("rule.guid '#{guid}' does not identify a rule", "#{path}.rule.guid")
        end
      end
    end

    private def validate_result_rule_consistency(reference : ReportingDescriptorReference, result : Result,
                                                 path : String, errors : Array(ValidationError))
      if (reference_id = reference.id) && (result_rule_id = result.rule_id) && reference_id != result_rule_id
        errors << ValidationError.new(
          "rule.id '#{reference_id}' must equal ruleId '#{result_rule_id}'",
          "#{path}.rule.id"
        )
      end

      if (reference_index = reference.index) && (result_rule_index = result.rule_index) && reference_index != result_rule_index
        errors << ValidationError.new(
          "rule.index #{reference_index} must equal ruleIndex #{result_rule_index}",
          "#{path}.rule.index"
        )
      end
    end

    private def validate_result_rule_ids(result : Result, descriptor : ReportingDescriptor, source : String,
                                         path : String, errors : Array(ValidationError))
      # Both ids have to identify the descriptor (§3.27.5, §3.52.4).
      {"ruleId" => result.rule_id, "rule.id" => result.rule.try(&.id)}.each do |label, rule_id|
        next if rule_id.nil? || descriptor.matches_id?(rule_id)
        errors << ValidationError.new("#{label} '#{rule_id}' does not match rule #{source} ('#{descriptor.id}')", "#{path}.#{label}")
      end
    end

    private def tool_component_pending?(run : Run, reference : ToolComponentReference?, component : ToolComponent?) : Bool
      return false unless refs = run.external_property_file_references
      if component
        return !!(refs.driver && run.tool.driver?.try(&.same?(component)))
      end

      extensions_external = refs.extensions.try(&.empty?) == false
      if (index = reference.try(&.index)) && index >= 0
        extensions_external
      elsif reference.try(&.guid)
        !refs.driver.nil? || extensions_external
      else
        !refs.driver.nil?
      end
    end

    # Schema constraints shared by every reportingDescriptorReference (§3.52):
    # it SHALL carry at least one of index, guid and id, and its index and
    # toolComponent are subject to the usual -1 sentinel and GUID rules.
    private def validate_descriptor_reference(reference : ReportingDescriptorReference, path : String,
                                              errors : Array(ValidationError), *, identified : Bool = false)
      if !identified && reference.index.nil? && reference.guid.nil? && reference.id.nil?
        errors << ValidationError.new(
          "reportingDescriptorReference must have at least one of index, guid or id",
          path
        )
      end
      validate_min(reference.index, NO_INDEX, "#{path}.index", "index", errors)
      validate_guid(reference.guid, "#{path}.guid", errors)

      validate_tool_component_reference(reference.tool_component, "#{path}.toolComponent", errors)
    end

    private def validate_tool_component_reference(reference : ToolComponentReference?, path : String, errors : Array(ValidationError))
      return unless reference
      validate_min(reference.index, NO_INDEX, "#{path}.index", "index", errors)
      validate_guid(reference.guid, "#{path}.guid", errors)
    end

    private def validate_min(value : Int?, min : Int, path : String, name : String,
                             errors : Array(ValidationError))
      if value && value < min
        errors << ValidationError.new("#{name} must be >= #{min}, got #{value}", path)
      end
    end

    private def validate_unique_values(values : Array(T)?, path : String, errors : Array(ValidationError)) forall T
      return unless values && values.size > 1
      seen = Set(T).new
      values.each_with_index do |value, i|
        unless seen.add?(value)
          errors << ValidationError.new("Duplicate value: #{value.inspect}", "#{path}[#{i}]")
        end
      end
    end

    # §3.11.11: `arguments` SHALL have as many elements as the highest
    # placeholder index (§3.11.5) among the message strings given by `text`,
    # `markdown` and `id` requires. The block looks `id` up (§3.11.7) and
    # returns nil when it cannot be resolved; then only `text` and `markdown`
    # are checked. §3.11.7 consults a descriptor's messageStrings only for
    # `result.message` and `notification.message`; other messages are checked
    # without an id lookup.
    private def validate_message(message : Message?, path : String, errors : Array(ValidationError),
                                 *, label : String = "Message", & : String -> MultiformatMessageString?)
      return unless message
      if message.text.nil? && message.id.nil?
        errors << ValidationError.new("#{label} must have either text or id", path)
      end
      if message.text.try(&.empty?)
        errors << ValidationError.new("Message text must not be empty", "#{path}.text")
      end
      if message.id.try(&.empty?)
        errors << ValidationError.new("Message id must not be empty", "#{path}.id")
      end
      if markdown = message.markdown
        if markdown.empty?
          errors << ValidationError.new("Message markdown must not be empty", "#{path}.markdown")
        elsif message.text.nil?
          errors << ValidationError.new("Message markdown requires plain text", "#{path}.markdown")
        end
      end

      strings = [message.text, message.markdown]
      if (id = message.id) && (looked_up = yield id)
        strings << looked_up.text << looked_up.markdown
      end
      max = strings.compact_map { |str| str.try { |text| max_placeholder(text) } }.max?
      return unless max
      count = message.arguments.try(&.size) || 0
      return if max < count
      errors << ValidationError.new(
        "message uses placeholder {#{max}} but arguments has #{count} element(s)",
        "#{path}.arguments"
      )
    end

    private def validate_message(message : Message?, path : String, errors : Array(ValidationError))
      validate_message(message, path, errors) { nil }
    end

    # The highest placeholder index (`{n}`, §3.11.5) in `str`, or nil when it
    # has none. `{{` is an escaped literal brace, so `{{0}}` is the text `{0}`,
    # not a placeholder. An index too large for UInt64 counts as UInt64::MAX.
    private def max_placeholder(str : String) : UInt64?
      bytes = str.to_slice
      max = nil
      i = 0
      while i < bytes.size
        unless bytes[i] == '{'.ord
          i += 1
          next
        end
        if bytes[i + 1]? == '{'.ord
          i += 2
          next
        end
        j = i + 1
        while j < bytes.size && bytes[j].unsafe_chr.ascii_number?
          j += 1
        end
        if j > i + 1 && bytes[j]? == '}'.ord
          n = str.byte_slice(i + 1, j - i - 1).to_u64? || UInt64::MAX
          max = n if max.nil? || n > max
          i = j + 1
        else
          i += 1
        end
      end
      max
    end

    private def validate_suppression(suppression : Suppression, run : Run, path : String,
                                     errors : Array(ValidationError), references : ResultLocationReferences)
      validate_enum(suppression.kind, "#{path}.kind", errors)
      validate_enum(suppression.status, "#{path}.status", errors)
      validate_guid(suppression.guid, "#{path}.guid", errors)

      if location = suppression.location
        validate_location(location, run, "#{path}.location", errors, references: references)
      end
    end

    private def validate_result_provenance(provenance : ResultProvenance, run : Run, path : String,
                                           errors : Array(ValidationError))
      first = validate_timestamp(provenance.first_detection_time_utc, "#{path}.firstDetectionTimeUtc", errors)
      last = validate_timestamp(provenance.last_detection_time_utc, "#{path}.lastDetectionTimeUtc", errors)
      validate_guid(provenance.first_detection_run_guid, "#{path}.firstDetectionRunGuid", errors)
      validate_guid(provenance.last_detection_run_guid, "#{path}.lastDetectionRunGuid", errors)
      validate_min(provenance.invocation_index, NO_INDEX, "#{path}.invocationIndex", "invocationIndex", errors)
      count = reference_count(run.invocations, run.external_property_file_references.try(&.invocations))
      validate_index_bound(provenance.invocation_index, count, "#{path}.invocationIndex", "invocationIndex", errors)
      provenance.conversion_sources.try &.each_with_index do |source, i|
        validate_physical_location(source, run, "#{path}.conversionSources[#{i}]", errors)
      end

      if first && last && first > last
        errors << ValidationError.new(
          "lastDetectionTimeUtc must not be before firstDetectionTimeUtc",
          "#{path}.lastDetectionTimeUtc"
        )
      end
    end

    private def validate_exception(exception : SarifException, run : Run, path : String,
                                   errors : Array(ValidationError), *, depth : Int32)
      return unless check_depth!(path, depth, errors)

      if ex_stack = exception.stack
        validate_stack(ex_stack, run, "#{path}.stack", errors)
      end

      exception.inner_exceptions.try &.each_with_index do |inner, i|
        validate_exception(inner, run, "#{path}.innerExceptions[#{i}]", errors, depth: depth + 1)
      end
    end

    private def validate_invocation(inv : Invocation, run : Run, path : String,
                                    errors : Array(ValidationError), *, depth : Int32)
      start_time = validate_timestamp(inv.start_time_utc, "#{path}.startTimeUtc", errors)
      end_time = validate_timestamp(inv.end_time_utc, "#{path}.endTimeUtc", errors)

      if start_time && end_time && start_time > end_time
        errors << ValidationError.new(
          "endTimeUtc must not be before startTimeUtc",
          "#{path}.endTimeUtc"
        )
      end

      {% for field in %w(executable_location working_directory stdin stdout stderr stdout_stderr) %}
        validate_artifact_location(inv.{{field.id}}, run, "#{path}." + {{field.camelcase(lower: true)}}, errors)
      {% end %}
      inv.response_files.try &.each_with_index do |location, i|
        validate_artifact_location(location, run, "#{path}.responseFiles[#{i}]", errors)
      end

      inv.rule_configuration_overrides.try &.each_with_index do |override, i|
        validate_configuration_override(override, "#{path}.ruleConfigurationOverrides[#{i}]", errors)
      end

      inv.notification_configuration_overrides.try &.each_with_index do |override, i|
        validate_configuration_override(override, "#{path}.notificationConfigurationOverrides[#{i}]", errors)
      end

      inv.tool_execution_notifications.try &.each_with_index do |notif, i|
        validate_notification(notif, run, "#{path}.toolExecutionNotifications[#{i}]", errors, depth: depth + 1)
      end

      inv.tool_configuration_notifications.try &.each_with_index do |notif, i|
        validate_notification(notif, run, "#{path}.toolConfigurationNotifications[#{i}]", errors, depth: depth + 1)
      end
    end

    private def validate_configuration_override(override : ConfigurationOverride, path : String,
                                                errors : Array(ValidationError))
      validate_descriptor_reference(override.descriptor, "#{path}.descriptor", errors)
      validate_reporting_configuration(override.configuration, "#{path}.configuration", errors)
    end

    private def validate_notification(notif : Notification, run : Run, path : String,
                                      errors : Array(ValidationError), *, depth : Int32)
      validate_message(notif.message, "#{path}.message", errors, label: "Notification message") do |id|
        reference = notif.descriptor
        component_reference = reference.try(&.tool_component)
        component = run.tool_component_for(component_reference)
        next nil if tool_component_pending?(run, component_reference, component)
        # §3.52.3 lookup, then the same id fallback `Result#resolve_rule` uses
        # (sarif-sdk style descriptors carry only an id).
        descriptor = reference.try { |ref| run.resolve_notification_reference(ref) } ||
                     reference.try(&.id).try { |rid| component.try(&.notifications).try &.find { |d| d.id == rid } }
        descriptor.try(&.message_strings).try(&.[id]?) ||
          component.try(&.global_message_strings).try(&.[id]?)
      end

      validate_enum(notif.level, "#{path}.level", errors)
      validate_timestamp(notif.time_utc, "#{path}.timeUtc", errors)

      if descriptor = notif.descriptor
        validate_descriptor_reference(descriptor, "#{path}.descriptor", errors)
      end
      if associated_rule = notif.associated_rule
        validate_descriptor_reference(associated_rule, "#{path}.associatedRule", errors)
      end

      notif.locations.try &.each_with_index do |loc, i|
        validate_location(loc, run, "#{path}.locations[#{i}]", errors)
      end

      if ex = notif.sarif_exception
        validate_exception(ex, run, "#{path}.exception", errors, depth: depth)
      end
    end

    private def validate_artifact(artifact : Artifact, run : Run, path : String, artifact_index : Int32,
                                  errors : Array(ValidationError))
      validate_message(artifact.description, "#{path}.description", errors)
      validate_artifact_location(artifact.location, run, "#{path}.location", errors)
      if (length = artifact.length) && length < -1
        errors << ValidationError.new(
          "artifact length must be >= -1, got #{length}",
          "#{path}.length"
        )
      end

      if (offset = artifact.offset) && offset < 0
        errors << ValidationError.new(
          "artifact offset must be >= 0, got #{offset}",
          "#{path}.offset"
        )
      end

      # -1 is the schema default and means "this artifact has no parent".
      if pi = artifact.parent_index
        artifact_count = reference_count(run.artifacts, run.external_property_file_references.try(&.artifacts))
        if pi < NO_INDEX
          errors << ValidationError.new(
            "artifact parentIndex must be >= -1, got #{pi}",
            "#{path}.parentIndex"
          )
        elsif pi == artifact_index
          errors << ValidationError.new(
            "artifact parentIndex #{pi} must not reference the artifact itself",
            "#{path}.parentIndex"
          )
        elsif pi != NO_INDEX && artifact_count && pi >= artifact_count
          errors << ValidationError.new(
            "artifact parentIndex #{pi} is out of range (#{artifact_count} artifacts defined)",
            "#{path}.parentIndex"
          )
        end
      end

      validate_unique_values(artifact.roles, "#{path}.roles", errors)
      artifact.roles.try &.each_with_index do |role, i|
        validate_enum(role, "#{path}.roles[#{i}]", errors)
      end

      validate_timestamp(artifact.last_modified_time_utc, "#{path}.lastModifiedTimeUtc", errors)
    end

    private def validate_version_control_details(vcd : VersionControlDetails, run : Run, path : String, errors : Array(ValidationError))
      if vcd.repository_uri.empty?
        errors << ValidationError.new(
          "repositoryUri must not be empty",
          "#{path}.repositoryUri"
        )
      else
        validate_uri(vcd.repository_uri, "#{path}.repositoryUri", errors)
      end

      validate_timestamp(vcd.as_of_time_utc, "#{path}.asOfTimeUtc", errors)
      validate_artifact_location(vcd.mapped_to, run, "#{path}.mappedTo", errors)
    end

    private def validate_code_flow(code_flow : CodeFlow, run : Run, path : String, errors : Array(ValidationError),
                                   references : ResultLocationReferences)
      validate_message(code_flow.message, "#{path}.message", errors)
      if code_flow.thread_flows.empty?
        errors << ValidationError.new(
          "codeFlow must have at least one threadFlow",
          "#{path}.threadFlows"
        )
      end

      code_flow.thread_flows.each_with_index do |tf, i|
        validate_message(tf.message, "#{path}.threadFlows[#{i}].message", errors)
        if tf.locations.empty?
          errors << ValidationError.new(
            "threadFlow must have at least one location",
            "#{path}.threadFlows[#{i}].locations"
          )
        end

        tf.locations.each_with_index do |tfl, j|
          validate_thread_flow_location(tfl, run, "#{path}.threadFlows[#{i}].locations[#{j}]", errors, references: references)
        end
      end
    end

    private def validate_thread_flow_location(tfl : ThreadFlowLocation, run : Run, path : String,
                                              errors : Array(ValidationError), *, references : ResultLocationReferences? = nil)
      validate_min(tfl.index, NO_INDEX, "#{path}.index", "index", errors)
      if references && (index = tfl.index) && index >= 0
        if cached = run.thread_flow_locations.try(&.[index]?)
          references.add_cached(index, cached, errors)
          # An indexed entry gets its locations from the cached object (§3.38.2).
          references = nil
        elsif count = reference_count(run.thread_flow_locations, run.external_property_file_references.try(&.thread_flow_locations))
          validate_index_bound(index, count, "#{path}.index", "threadFlowLocation index", errors)
        else
          references.complete = false
        end
      end
      validate_min(tfl.nesting_level, 0, "#{path}.nestingLevel", "nestingLevel", errors)
      validate_min(tfl.execution_order, NO_INDEX, "#{path}.executionOrder", "executionOrder", errors)
      validate_enum(tfl.importance, "#{path}.importance", errors)
      validate_timestamp(tfl.execution_time_utc, "#{path}.executionTimeUtc", errors)
      validate_unique_values(tfl.kinds, "#{path}.kinds", errors)
      validate_min(tfl.web_request.try(&.index), NO_INDEX, "#{path}.webRequest.index", "index", errors)
      validate_min(tfl.web_response.try(&.index), NO_INDEX, "#{path}.webResponse.index", "index", errors)
      if stack = tfl.stack
        validate_stack(stack, run, "#{path}.stack", errors, references: references)
      end
      tfl.taxa.try &.each_with_index do |taxon, k|
        validate_descriptor_reference(taxon, "#{path}.taxa[#{k}]", errors)
      end
      if location = tfl.location
        validate_location(location, run, "#{path}.location", errors, references: references)
      end
    end

    private def validate_fix(fix : Fix, run : Run, path : String, errors : Array(ValidationError))
      validate_message(fix.description, "#{path}.description", errors)
      if fix.artifact_changes.empty?
        errors << ValidationError.new(
          "fix must have at least one artifactChange",
          "#{path}.artifactChanges"
        )
      end

      fix.artifact_changes.each_with_index do |change, i|
        validate_artifact_location(change.artifact_location, run, "#{path}.artifactChanges[#{i}].artifactLocation", errors)
        if change.replacements.empty?
          errors << ValidationError.new(
            "artifactChange must have at least one replacement",
            "#{path}.artifactChanges[#{i}].replacements"
          )
        end

        change.replacements.each_with_index do |replacement, j|
          validate_region(
            replacement.deleted_region,
            "#{path}.artifactChanges[#{i}].replacements[#{j}].deletedRegion",
            errors
          )
        end
      end
    end

    private def validate_location(location : Location, run : Run, path : String,
                                  errors : Array(ValidationError), *, references : ResultLocationReferences? = nil)
      validate_min(location.id, NO_INDEX, "#{path}.id", "location id", errors)
      references.try &.add(location, path, errors)
      validate_message(location.message, "#{path}.message", errors)
      location.relationships.try &.each_with_index do |relationship, i|
        relationship_path = "#{path}.relationships[#{i}]"
        validate_min(relationship.target, 0, "#{relationship_path}.target", "target", errors)
        if relationship.kinds.try(&.empty?)
          errors << ValidationError.new("Location relationship kinds must contain at least one value", "#{relationship_path}.kinds")
        end
        validate_unique_values(relationship.kinds, "#{relationship_path}.kinds", errors)
        validate_message(relationship.description, "#{relationship_path}.description", errors)
      end
      if logical_locations = location.logical_locations
        count = reference_count(run.logical_locations, run.external_property_file_references.try(&.logical_locations))
        logical_locations.each_with_index do |logical, i|
          logical_path = "#{path}.logicalLocations[#{i}]"
          validate_logical_location(logical, logical_path, errors)
          validate_index_bound(logical.index, count, "#{logical_path}.index", "logicalLocation index", errors)
        end
      end

      if physical = location.physical_location
        validate_physical_location(physical, run, "#{path}.physicalLocation", errors)
      end

      location.annotations.try &.each_with_index do |annotated_region, i|
        validate_region(annotated_region, "#{path}.annotations[#{i}]", errors)
      end
    end

    private def validate_physical_location(physical : PhysicalLocation, run : Run, path : String,
                                           errors : Array(ValidationError))
      if physical.artifact_location.nil? && physical.address.nil?
        errors << ValidationError.new(
          "physicalLocation must have either artifactLocation or address",
          path
        )
      end

      validate_artifact_location(physical.artifact_location, run, "#{path}.artifactLocation", errors)
      if address = physical.address
        validate_address(address, "#{path}.address", errors)
      end

      if region = physical.region
        validate_region(region, "#{path}.region", errors)
      end

      if context_region = physical.context_region
        validate_region(context_region, "#{path}.contextRegion", errors)

        # A contextRegion only has meaning as a superset of region (§3.29.5).
        if physical.region.nil?
          errors << ValidationError.new(
            "contextRegion must be absent when region is absent",
            "#{path}.contextRegion"
          )
        end
      end
    end

    private def validate_artifact_location(location : ArtifactLocation?, run : Run, path : String, errors : Array(ValidationError))
      return unless location
      if index = location.index
        count = reference_count(run.artifacts, run.external_property_file_references.try(&.artifacts))
        validate_min(index, NO_INDEX, "#{path}.index", "index", errors)
        validate_index_bound(index, count, "#{path}.index", "artifact index", errors)
      end
      validate_message(location.description, "#{path}.description", errors)
    end

    private def validate_logical_location(location : LogicalLocation, path : String, errors : Array(ValidationError))
      validate_min(location.index, NO_INDEX, "#{path}.index", "index", errors)
      validate_min(location.parent_index, NO_INDEX, "#{path}.parentIndex", "parentIndex", errors)
    end

    private def validate_address(address : Address, path : String, errors : Array(ValidationError))
      validate_min(address.absolute_address, -1, "#{path}.absoluteAddress", "absoluteAddress", errors)
      validate_min(address.index, NO_INDEX, "#{path}.index", "index", errors)
      validate_min(address.parent_index, NO_INDEX, "#{path}.parentIndex", "parentIndex", errors)
    end

    private def validate_region(region : Region, path : String,
                                errors : Array(ValidationError))
      validate_message(region.message, "#{path}.message", errors)
      # A region SHALL define a text region or a binary region (§3.30.1); the
      # schema requires at least one of startLine, charOffset or byteOffset.
      if region.start_line.nil? && region.char_offset.nil? && region.byte_offset.nil?
        errors << ValidationError.new(
          "region must define a text region (startLine or charOffset) or a binary region (byteOffset)",
          path
        )
      end

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

      validate_region_offsets(region, path, errors)

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

    # -1 is the schema default for the binary and character offsets and means
    # "absent"; the matching lengths have no such sentinel and are simply
    # non-negative.
    private def validate_region_offsets(region : Region, path : String,
                                        errors : Array(ValidationError))
      if (bo = region.byte_offset) && bo < NO_INDEX
        errors << ValidationError.new(
          "byteOffset must be >= -1, got #{bo}",
          "#{path}.byteOffset"
        )
      end

      if (bl = region.byte_length) && bl < 0
        errors << ValidationError.new(
          "byteLength must be >= 0, got #{bl}",
          "#{path}.byteLength"
        )
      end

      if (co = region.char_offset) && co < NO_INDEX
        errors << ValidationError.new(
          "charOffset must be >= -1, got #{co}",
          "#{path}.charOffset"
        )
      end

      if (cl = region.char_length) && cl < 0
        errors << ValidationError.new(
          "charLength must be >= 0, got #{cl}",
          "#{path}.charLength"
        )
      end
    end

    private def validate_guid(value : String?, path : String, errors : Array(ValidationError))
      return unless value
      unless GUID_PATTERN.matches?(value)
        errors << ValidationError.new(
          "Invalid GUID format: '#{value}'. Expected an RFC 4122 UUID (xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx, M = 1-5, N = 8, 9, a or b)",
          path
        )
      end
    end

    private def validate_timestamp(value : String?, path : String, errors : Array(ValidationError)) : Tuple(Int64, Int32, String)?
      return unless value
      if timestamp = parse_timestamp(value)
        return timestamp
      end
      errors << ValidationError.new(
        "Invalid timestamp format: '#{value}'. Expected a SARIF date or date/time (e.g., 2024-01-01T00:00:00Z)",
        path
      )
      nil
    end

    # §3.9 allows dates, minute precision, 24:00, leap seconds and arbitrary
    # fractional precision. Also accept RFC 3339 offsets for compatibility.
    private def parse_timestamp(value : String) : Tuple(Int64, Int32, String)?
      return unless match = TIMESTAMP_PATTERN.match(value)
      date = Time.utc(match[1].to_i, match[2].to_i, match[3].to_i)
      hour = match[4]?.try(&.to_i) || 0
      minute = match[5]?.try(&.to_i) || 0
      second = match[6]?.try(&.to_i) || 0
      fraction = match[7]?.try(&.rstrip('0')) || ""
      return if hour > 24 || minute > 59 || second > 60
      return if hour == 24 && (minute != 0 || second != 0 || !fraction.empty?)

      offset = 0
      if (zone = match[8]?) && zone != "Z"
        offset_hour, offset_minute = zone[1, 2].to_i, zone[4, 2].to_i
        return if match[6]?.nil? || offset_hour > 23 || offset_minute > 59
        offset = (offset_hour * 60 + offset_minute) * (zone.starts_with?('-') ? -1 : 1)
      end

      # Compare leap seconds after :59 fractions and before the next minute.
      # Fractions compare as strings once trailing zeroes are removed.
      seconds = date.to_unix + hour * 3600 + (minute - offset) * 60 + Math.min(second, 59)
      {seconds, second == 60 ? 1 : 0, fraction}
    rescue ArgumentError
      nil
    end

    # Reports an enum-valued property whose input string was outside the SARIF
    # 2.1.0 vocabulary. Tolerant deserialization (the default, see
    # `Sarif.strict_enums`) maps such a string onto the enum's `Unknown`
    # sentinel so one bad value cannot abort a whole document parse; validation
    # is where those values have to surface.
    private def validate_enum(value : T?, path : String, errors : Array(ValidationError)) forall T
      return unless value
      return unless value == T::Unknown

      errors << ValidationError.new(
        "Value is not part of the SARIF 2.1.0 vocabulary for this property",
        path
      )
    end

    private def validate_uri(value : String?, path : String, errors : Array(ValidationError))
      return unless value
      unless URI_PATTERN.matches?(value)
        errors << ValidationError.new(
          "Invalid URI format: '#{value}'. Expected absolute URI with scheme",
          path
        )
      end
    end

    # §3.14.14: a relative `uri` needs a `uriBaseId`, an absolute or absent one
    # must not have one; a `uri` ends with "/", has no query, fragment or ".."
    # segment; and the `uriBaseId` chains must not loop. A `uriBaseId` naming
    # no entry is not an error, since the consumer may supply it (§3.4.4).
    private def validate_original_uri_base_ids(base_ids : Hash(String, ArtifactLocation), run : Run, path : String,
                                               errors : Array(ValidationError))
      loops = uri_base_id_loops(base_ids)
      base_ids.each do |name, location|
        entry_path = "#{path}.#{name}"
        validate_artifact_location(location, run, entry_path, errors)
        uri = location.uri
        absolute = uri && URI_PATTERN.matches?(uri)
        if uri && !absolute && location.uri_base_id.nil?
          errors << ValidationError.new("A relative uri in originalUriBaseIds requires a uriBaseId", entry_path)
        elsif (uri.nil? || absolute) && location.uri_base_id
          errors << ValidationError.new("uriBaseId must be absent when uri is absolute or absent", entry_path)
        end

        if uri
          unless uri.ends_with?('/')
            errors << ValidationError.new("originalUriBaseIds uri '#{uri}' must end with '/'", "#{entry_path}.uri")
          end
          if uri.includes?('?') || uri.includes?('#')
            errors << ValidationError.new("originalUriBaseIds uri '#{uri}' must not have a query or fragment", "#{entry_path}.uri")
          end
          # %2E is an encoded "." (RFC 3986 §2.3, §6.2.2.2).
          if uri.split('/').any? { |seg| seg.gsub(/%2e/i, ".") == ".." }
            errors << ValidationError.new("originalUriBaseIds uri '#{uri}' must not contain '..' segments", "#{entry_path}.uri")
          end
        end

        if loops.includes?(name)
          errors << ValidationError.new("uriBaseId chain starting at '#{name}' loops back to it", "#{entry_path}.uriBaseId")
        end
      end
    end

    # The entries whose §3.14.14 resolution procedure comes back to them.
    # Entries on a chain that only leads into a loop are not members. Each
    # entry is walked once, so a long chain stays linear.
    private def uri_base_id_loops(base_ids : Hash(String, ArtifactLocation)) : Set(String)
      loops = Set(String).new
      done = Set(String).new
      base_ids.each_key do |start|
        walk = {} of String => Int32 # name => position in this walk
        name = start
        while name && !done.includes?(name) && (location = base_ids[name]?)
          if position = walk[name]?
            walk.each { |member, at| loops << member if at >= position }
            break
          end
          walk[name] = walk.size
          name = location.uri.try { |u| URI_PATTERN.matches?(u) } ? nil : location.uri_base_id
        end
        done.concat(walk.keys)
      end
      loops
    end

    private def validate_graph_traversal(gt : GraphTraversal, run : Run, result : Result, path : String,
                                         errors : Array(ValidationError), graph_edge_ids : Hash(Graph, Set(String)))
      validate_message(gt.description, "#{path}.description", errors)
      # Exactly one of the two SHALL be present (§3.42.2).
      if gt.run_graph_index.nil? == gt.result_graph_index.nil?
        errors << ValidationError.new(
          "graphTraversal must have exactly one of runGraphIndex or resultGraphIndex",
          path
        )
      end
      if index = gt.run_graph_index
        validate_min(index, 0, "#{path}.runGraphIndex", "runGraphIndex", errors)
        graph = run.graphs.try(&.[index]?) if index >= 0
        if index >= 0 && !graph && run.external_property_file_references.try(&.graphs).try(&.empty?) != false
          errors << ValidationError.new("runGraphIndex #{index} does not identify a graph", "#{path}.runGraphIndex")
        end
      elsif index = gt.result_graph_index
        validate_min(index, 0, "#{path}.resultGraphIndex", "resultGraphIndex", errors)
        graph = result.graphs.try(&.[index]?) if index >= 0
        if index >= 0 && !graph
          errors << ValidationError.new("resultGraphIndex #{index} does not identify a graph", "#{path}.resultGraphIndex")
        end
      end

      if (traversals = gt.edge_traversals) && !traversals.empty?
        edge_ids = graph.try do |g|
          graph_edge_ids[g] ||= Set(String).new.tap do |ids|
            g.edges.try &.each { |edge| ids << edge.id }
          end
        end
        traversals.each_with_index do |edge, i|
          edge_path = "#{path}.edgeTraversals[#{i}]"
          validate_message(edge.message, "#{edge_path}.message", errors)
          validate_min(edge.step_over_edge_count, 0, "#{edge_path}.stepOverEdgeCount", "stepOverEdgeCount", errors)
          if edge_ids && !edge_ids.includes?(edge.edge_id)
            errors << ValidationError.new("Unknown edgeId '#{edge.edge_id}'", "#{edge_path}.edgeId")
          end
        end
      end
    end

    private def validate_stack(stack : Stack, run : Run, path : String,
                               errors : Array(ValidationError), *, references : ResultLocationReferences? = nil)
      validate_message(stack.message, "#{path}.message", errors)
      stack.frames.each_with_index do |frame, i|
        if location = frame.location
          validate_location(location, run, "#{path}.frames[#{i}].location", errors, references: references)
        end
      end
    end

    private def validate_graph(graph : Graph, run : Run, path : String,
                               errors : Array(ValidationError), *, references : ResultLocationReferences? = nil)
      validate_message(graph.description, "#{path}.description", errors)
      node_ids = Set(String).new
      if nodes = graph.nodes
        nodes.each_with_index do |node, i|
          validate_node(node, run, "#{path}.nodes[#{i}]", node_ids, errors, depth: 1, references: references)
        end
      end

      if edges = graph.edges
        edge_ids = Set(String).new
        edges.each_with_index do |edge, i|
          validate_edge(edge, "#{path}.edges[#{i}]", edge_ids, node_ids, errors)
        end
      end
    end

    private def validate_node(node : Node, run : Run, path : String, seen_ids : Set(String),
                              errors : Array(ValidationError), *, depth : Int32, references : ResultLocationReferences?)
      validate_message(node.label, "#{path}.label", errors)
      # Bound recursion through node.children so a malformed SARIF graph
      # with arbitrarily deep child chains can't blow the call stack.
      unless check_depth!(path, depth, errors)
        references.try { |refs| refs.complete = false }
        return
      end

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

      if location = node.location
        validate_location(location, run, "#{path}.location", errors, references: references)
      end

      node.children.try &.each_with_index do |child, i|
        validate_node(child, run, "#{path}.children[#{i}]", seen_ids, errors, depth: depth + 1, references: references)
      end
    end

    private def validate_edge(edge : Edge, path : String, seen_ids : Set(String),
                              node_ids : Set(String), errors : Array(ValidationError))
      validate_message(edge.label, "#{path}.label", errors)
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
      elsif !node_ids.includes?(edge.source_node_id)
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
      elsif !node_ids.includes?(edge.target_node_id)
        errors << ValidationError.new(
          "edge targetNodeId '#{edge.target_node_id}' references unknown node",
          "#{path}.targetNodeId"
        )
      end
    end

    private def validate_reporting_configuration(config : ReportingConfiguration, path : String,
                                                 errors : Array(ValidationError))
      validate_enum(config.level, "#{path}.level", errors)

      if (rank = config.rank) && !Sarif.valid_rank?(rank)
        errors << ValidationError.new(
          "rank must be between 0.0 and 100.0 (or -1.0 for unknown), got #{rank}",
          "#{path}.rank"
        )
      end
    end

    # The default for an absent array is empty (§3.7.2). A reference to
    # external data leaves the upper bound unknown until resolution.
    private def reference_count(items : Array?, external : Array(ExternalPropertyFileReference)?) : Int32?
      return if external && !external.empty?
      items.try(&.size) || 0
    end

    private def validate_index_bound(index : Int32?, count : Int32?, path : String, name : String, errors : Array(ValidationError))
      if index && index >= 0 && count && index >= count
        errors << ValidationError.new("#{name} #{index} is out of range (#{count} entries defined)", path)
      end
    end

    private def validate_external_property_file_references(refs : ExternalPropertyFileReferences, run : Run, path : String,
                                                           errors : Array(ValidationError))
      if conversion = refs.conversion
        validate_external_property_file_reference(conversion, run, "#{path}.conversion", errors, object: true)
      end
      refs.graphs.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.graphs[#{i}]", errors)
      end
      if ext_props = refs.externalized_properties
        validate_external_property_file_reference(ext_props, run, "#{path}.externalizedProperties", errors, object: true)
      end
      refs.artifacts.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.artifacts[#{i}]", errors)
      end
      refs.invocations.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.invocations[#{i}]", errors)
      end
      refs.logical_locations.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.logicalLocations[#{i}]", errors)
      end
      refs.thread_flow_locations.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.threadFlowLocations[#{i}]", errors)
      end
      refs.results.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.results[#{i}]", errors)
      end
      refs.taxonomies.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.taxonomies[#{i}]", errors)
      end
      refs.addresses.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.addresses[#{i}]", errors)
      end
      if driver = refs.driver
        validate_external_property_file_reference(driver, run, "#{path}.driver", errors, object: true)
      end
      refs.extensions.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.extensions[#{i}]", errors)
      end
      refs.policies.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.policies[#{i}]", errors)
      end
      refs.translations.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.translations[#{i}]", errors)
      end
      refs.web_requests.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.webRequests[#{i}]", errors)
      end
      refs.web_responses.try &.each_with_index do |item, i|
        validate_external_property_file_reference(item, run, "#{path}.webResponses[#{i}]", errors)
      end
    end

    private def validate_external_property_file_reference(ref : ExternalPropertyFileReference, run : Run, path : String,
                                                          errors : Array(ValidationError), *, object : Bool = false)
      if ref.location.nil? && ref.guid.nil?
        errors << ValidationError.new(
          "externalPropertyFileReference must have either location or guid",
          path
        )
      end

      validate_guid(ref.guid, "#{path}.guid", errors)
      validate_artifact_location(ref.location, run, "#{path}.location", errors)
      if object && ref.item_count
        errors << ValidationError.new("itemCount must be absent for an object-valued property", "#{path}.itemCount")
      else
        validate_min(ref.item_count, -1, "#{path}.itemCount", "itemCount", errors)
      end
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
