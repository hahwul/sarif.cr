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
    end

    private def validate_tool(tool : Tool, path : String, errors : Array(ValidationError))
      if tool.driver.name.empty?
        errors << ValidationError.new("Tool driver name must not be empty", "#{path}.driver.name")
      end
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

      result.locations.try &.each_with_index do |loc, k|
        validate_location(loc, "#{path}.locations[#{k}]", errors)
      end

      result.related_locations.try &.each_with_index do |loc, k|
        validate_location(loc, "#{path}.relatedLocations[#{k}]", errors)
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
  end
end
