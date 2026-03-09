module Sarif
  class Builder
    @runs = [] of Run

    def self.build(& : Builder ->) : SarifLog
      builder = new
      yield builder
      builder.to_sarif_log
    end

    def run(name : String, version : String? = nil, & : RunBuilder ->) : self
      run_builder = RunBuilder.new(name, version)
      yield run_builder
      @runs << run_builder.build
      self
    end

    def to_sarif_log : SarifLog
      SarifLog.new(runs: @runs)
    end
  end

  class RunBuilder
    @name : String
    @version : String?
    @rules = [] of ReportingDescriptor
    @results = [] of Result
    @artifacts = [] of Artifact
    @invocations = [] of Invocation
    @information_uri : String? = nil

    def initialize(@name : String, @version : String? = nil)
    end

    def information_uri(@information_uri : String) : self
      self
    end

    def rule(id : String, name : String? = nil, short_description : String? = nil,
             full_description : String? = nil, help_uri : String? = nil,
             level : Level? = nil) : self
      short_desc = short_description ? MultiformatMessageString.new(text: short_description) : nil
      full_desc = full_description ? MultiformatMessageString.new(text: full_description) : nil
      default_config = level ? ReportingConfiguration.new(level: level) : nil
      @rules << ReportingDescriptor.new(
        id: id, name: name,
        short_description: short_desc,
        full_description: full_desc,
        help_uri: help_uri,
        default_configuration: default_config
      )
      self
    end

    def result(text : String, rule_id : String? = nil, level : Level? = nil,
               kind : ResultKind? = nil, uri : String? = nil, start_line : Int32? = nil,
               start_column : Int32? = nil, end_line : Int32? = nil,
               end_column : Int32? = nil) : self
      message = Message.new(text: text)
      locations = nil
      if uri || start_line
        region = nil
        if start_line
          region = Region.new(start_line: start_line, start_column: start_column,
                              end_line: end_line, end_column: end_column)
        end
        artifact_loc = uri ? ArtifactLocation.new(uri: uri) : nil
        physical = PhysicalLocation.new(artifact_location: artifact_loc, region: region)
        locations = [Location.new(physical_location: physical)]
      end

      rule_index = nil
      if rule_id
        idx = @rules.index { |r| r.id == rule_id }
        rule_index = idx.as(Int32) if idx
      end

      @results << Result.new(
        message: message, rule_id: rule_id, level: level, kind: kind,
        locations: locations, rule_index: rule_index
      )
      self
    end

    def result(& : ResultBuilder ->) : self
      result_builder = ResultBuilder.new
      yield result_builder
      @results << result_builder.build(@rules)
      self
    end

    def artifact(uri : String, mime_type : String? = nil,
                 source_language : String? = nil) : self
      @artifacts << Artifact.new(
        location: ArtifactLocation.new(uri: uri),
        mime_type: mime_type, source_language: source_language
      )
      self
    end

    def invocation(execution_successful : Bool, command_line : String? = nil) : self
      @invocations << Invocation.new(
        execution_successful: execution_successful,
        command_line: command_line
      )
      self
    end

    def build : Run
      driver = ToolComponent.new(
        name: @name, version: @version, information_uri: @information_uri,
        rules: @rules.empty? ? nil : @rules
      )
      tool = Tool.new(driver: driver)
      Run.new(
        tool: tool,
        results: @results.empty? ? nil : @results,
        artifacts: @artifacts.empty? ? nil : @artifacts,
        invocations: @invocations.empty? ? nil : @invocations
      )
    end
  end

  class ResultBuilder
    @text : String = ""
    @markdown : String? = nil
    @rule_id : String? = nil
    @level : Level? = nil
    @kind : ResultKind? = nil
    @locations = [] of Location
    @related_locations = [] of Location
    @code_flows = [] of CodeFlow
    @fixes = [] of Fix
    @fingerprints : Hash(String, String)? = nil
    @partial_fingerprints : Hash(String, String)? = nil

    def message(@text : String, @markdown : String? = nil) : self
      self
    end

    def rule_id(@rule_id : String) : self
      self
    end

    def level(@level : Level) : self
      self
    end

    def kind(@kind : ResultKind) : self
      self
    end

    def location(uri : String? = nil, start_line : Int32? = nil,
                 start_column : Int32? = nil, end_line : Int32? = nil,
                 end_column : Int32? = nil) : self
      region = nil
      if start_line
        region = Region.new(start_line: start_line, start_column: start_column,
                            end_line: end_line, end_column: end_column)
      end
      artifact_loc = uri ? ArtifactLocation.new(uri: uri) : nil
      physical = PhysicalLocation.new(artifact_location: artifact_loc, region: region)
      @locations << Location.new(physical_location: physical)
      self
    end

    def related_location(uri : String, start_line : Int32? = nil, message_text : String? = nil,
                         id : Int32? = nil) : self
      region = start_line ? Region.new(start_line: start_line) : nil
      artifact_loc = ArtifactLocation.new(uri: uri)
      physical = PhysicalLocation.new(artifact_location: artifact_loc, region: region)
      msg = message_text ? Message.new(text: message_text) : nil
      @related_locations << Location.new(id: id, physical_location: physical, message: msg)
      self
    end

    def fingerprint(key : String, value : String) : self
      @fingerprints ||= {} of String => String
      @fingerprints.not_nil![key] = value
      self
    end

    def partial_fingerprint(key : String, value : String) : self
      @partial_fingerprints ||= {} of String => String
      @partial_fingerprints.not_nil![key] = value
      self
    end

    def build(rules : Array(ReportingDescriptor)) : Result
      rule_index = nil
      if rid = @rule_id
        idx = rules.index { |r| r.id == rid }
        rule_index = idx.as(Int32) if idx
      end

      Result.new(
        message: Message.new(text: @text, markdown: @markdown),
        rule_id: @rule_id, level: @level, kind: @kind,
        rule_index: rule_index,
        locations: @locations.empty? ? nil : @locations,
        related_locations: @related_locations.empty? ? nil : @related_locations,
        code_flows: @code_flows.empty? ? nil : @code_flows,
        fixes: @fixes.empty? ? nil : @fixes,
        fingerprints: @fingerprints,
        partial_fingerprints: @partial_fingerprints
      )
    end
  end
end
