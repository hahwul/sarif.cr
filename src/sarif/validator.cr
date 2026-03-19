module Sarif
  class Error < Exception
  end

  class ValidationError < Error
    getter path : String

    def initialize(message : String, @path : String = "")
      super(message)
    end

    def to_s(io : IO) : Nil
      if @path.empty?
        io << message
      else
        io << @path << ": " << message
      end
    end
  end

  class ParseError < Error
    getter validation_errors : Array(ValidationError)

    def initialize(@validation_errors : Array(ValidationError))
      messages = @validation_errors.map(&.to_s).join("; ")
      super("SARIF validation failed: #{messages}")
    end
  end

  class ValidationResult
    getter errors : Array(ValidationError)

    def initialize(@errors : Array(ValidationError) = [] of ValidationError)
    end

    def valid? : Bool
      @errors.empty?
    end
  end

  class Validator
    private GUID_PATTERN = /\A[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\z/
    private RFC3339_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})\z/
    private URI_PATTERN     = /\A[a-zA-Z][a-zA-Z0-9+\-.]*:/

    def validate(log : SarifLog) : ValidationResult
      errors = [] of ValidationError

      validate_version(log, errors)
      validate_runs(log, errors)

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

    private def validate_runs(log : SarifLog, errors : Array(ValidationError))
      log.runs.each_with_index do |run, i|
        validate_run(run, "$.runs[#{i}]", errors)
      end
    end

    private def validate_run(run : Run, path : String, errors : Array(ValidationError))
      validate_tool(run.tool, "#{path}.tool", errors)

      run.results.try &.each_with_index do |result, j|
        validate_result(result, run, "#{path}.results[#{j}]", errors)
      end

      run.invocations.try &.each_with_index do |inv, j|
        validate_invocation(inv, "#{path}.invocations[#{j}]", errors)
      end

      run.artifacts.try &.each_with_index do |artifact, j|
        validate_artifact(artifact, "#{path}.artifacts[#{j}]", errors)
      end

      run.version_control_provenance.try &.each_with_index do |vcd, j|
        validate_version_control_details(vcd, "#{path}.versionControlProvenance[#{j}]", errors)
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

      component.rules.try &.each_with_index do |rule, i|
        validate_reporting_descriptor(rule, "#{path}.rules[#{i}]", errors)
      end

      component.notifications.try &.each_with_index do |notif, i|
        validate_reporting_descriptor(notif, "#{path}.notifications[#{i}]", errors)
      end
    end

    private def validate_reporting_descriptor(descriptor : ReportingDescriptor, path : String, errors : Array(ValidationError))
      if descriptor.id.empty?
        errors << ValidationError.new("ReportingDescriptor id must not be empty", "#{path}.id")
      end

      validate_guid(descriptor.guid, "#{path}.guid", errors)
      validate_uri(descriptor.help_uri, "#{path}.helpUri", errors)
    end

    private def validate_result(result : Result, run : Run, path : String,
                                errors : Array(ValidationError))
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
        end
      end

      if rule_id = result.rule_id
        if rule_index = result.rule_index
          rules = run.tool.driver.rules
          if rules && rule_index >= 0 && rule_index < rules.size
            if rules[rule_index].id != rule_id
              errors << ValidationError.new(
                "ruleId '#{rule_id}' does not match rule at ruleIndex #{rule_index} ('#{rules[rule_index].id}')",
                "#{path}.ruleId"
              )
            end
          end
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

      result.fixes.try &.each_with_index do |fix, k|
        validate_fix(fix, "#{path}.fixes[#{k}]", errors)
      end
    end

    private def validate_invocation(inv : Invocation, path : String, errors : Array(ValidationError))
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
    end

    private def validate_artifact(artifact : Artifact, path : String, errors : Array(ValidationError))
      if (length = artifact.length) && length < -1
        errors << ValidationError.new(
          "artifact length must be >= -1, got #{length}",
          "#{path}.length"
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
        if region = physical.region
          validate_region(region, "#{path}.physicalLocation.region", errors)
        end
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
  end
end
