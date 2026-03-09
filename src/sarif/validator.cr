module Sarif
  class ValidationError
    getter message : String
    getter path : String

    def initialize(@message : String, @path : String = "")
    end

    def to_s(io : IO) : Nil
      if @path.empty?
        io << @message
      else
        io << @path << ": " << @message
      end
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
    end
  end
end
