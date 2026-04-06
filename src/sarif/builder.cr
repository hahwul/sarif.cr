module Sarif
  # DSL for building SARIF documents programmatically.
  #
  # ```
  # log = Sarif::Builder.build do |b|
  #   b.run("MyLinter", "1.0") do |r|
  #     r.rule("R001", short_description: "Unused variable")
  #     r.result("Found unused var", rule_id: "R001",
  #       level: Sarif::Level::Warning, uri: "src/main.cr", start_line: 10)
  #   end
  # end
  # ```
  class Builder
    @runs = [] of Run

    # Builds a `SarifLog` using the builder DSL.
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

  # :nodoc:
  protected def self.build_location(uri : String? = nil, start_line : Int32? = nil,
                                    start_column : Int32? = nil, end_line : Int32? = nil,
                                    end_column : Int32? = nil) : Location
    region = if start_line
               Region.new(start_line: start_line, start_column: start_column,
                 end_line: end_line, end_column: end_column)
             end
    artifact_loc = uri ? ArtifactLocation.new(uri: uri) : nil
    physical = PhysicalLocation.new(artifact_location: artifact_loc, region: region)
    Location.new(physical_location: physical)
  end

  # :nodoc:
  protected def self.find_rule_index(rules : Array(ReportingDescriptor), rule_id : String?) : Int32?
    return nil unless rule_id
    rules.index { |r| r.id == rule_id }
  end

  # :nodoc:
  protected def self.nil_if_empty(arr : Array(T)) : Array(T)? forall T
    arr.empty? ? nil : arr
  end

  class RunBuilder
    @name : String
    @version : String?
    @rules = [] of ReportingDescriptor
    @results = [] of Result
    @artifacts = [] of Artifact
    @invocations = [] of Invocation
    @graphs = [] of Graph
    @version_control_provenance = [] of VersionControlDetails
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
      locations = if uri || start_line
                    [Sarif.build_location(uri: uri, start_line: start_line,
                      start_column: start_column, end_line: end_line, end_column: end_column)]
                  end

      @results << Result.new(
        message: message, rule_id: rule_id, level: level, kind: kind,
        locations: locations, rule_index: Sarif.find_rule_index(@rules, rule_id)
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

    def graph(description : String? = nil, & : GraphBuilder ->) : self
      builder = GraphBuilder.new(description)
      yield builder
      @graphs << builder.build
      self
    end

    def version_control(repository_uri : String, revision_id : String? = nil,
                        branch : String? = nil, revision_tag : String? = nil,
                        as_of_time_utc : String? = nil, mapped_to : String? = nil) : self
      mapped = mapped_to ? ArtifactLocation.new(uri: mapped_to) : nil
      @version_control_provenance << VersionControlDetails.new(
        repository_uri: repository_uri, revision_id: revision_id,
        branch: branch, revision_tag: revision_tag,
        as_of_time_utc: as_of_time_utc, mapped_to: mapped
      )
      self
    end

    def build : Run
      driver = ToolComponent.new(
        name: @name, version: @version, information_uri: @information_uri,
        rules: Sarif.nil_if_empty(@rules)
      )
      tool = Tool.new(driver: driver)
      Run.new(
        tool: tool,
        results: Sarif.nil_if_empty(@results),
        artifacts: Sarif.nil_if_empty(@artifacts),
        invocations: Sarif.nil_if_empty(@invocations),
        graphs: Sarif.nil_if_empty(@graphs),
        version_control_provenance: Sarif.nil_if_empty(@version_control_provenance)
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
    @suppressions = [] of Suppression
    @stacks = [] of Stack
    @graphs = [] of Graph
    @fingerprints : Hash(String, String)? = nil
    @partial_fingerprints : Hash(String, String)? = nil
    @web_request : WebRequest? = nil
    @web_response : WebResponse? = nil

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
      @locations << Sarif.build_location(uri: uri, start_line: start_line,
        start_column: start_column, end_line: end_line, end_column: end_column)
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

    def code_flow(code_flow : CodeFlow) : self
      @code_flows << code_flow
      self
    end

    def code_flow(message : String? = nil, & : CodeFlowBuilder ->) : self
      builder = CodeFlowBuilder.new(message)
      yield builder
      @code_flows << builder.build
      self
    end

    def fix(fix : Fix) : self
      @fixes << fix
      self
    end

    def fix(description : String? = nil, & : FixBuilder ->) : self
      builder = FixBuilder.new(description)
      yield builder
      @fixes << builder.build
      self
    end

    def suppression(kind : SuppressionKind, justification : String? = nil,
                    status : SuppressionStatus? = nil) : self
      @suppressions << Suppression.new(kind: kind, justification: justification, status: status)
      self
    end

    def stack(message : String? = nil, & : StackBuilder ->) : self
      builder = StackBuilder.new(message)
      yield builder
      @stacks << builder.build
      self
    end

    def graph(description : String? = nil, & : GraphBuilder ->) : self
      builder = GraphBuilder.new(description)
      yield builder
      @graphs << builder.build
      self
    end

    def web_request(target : String, method : String = "GET",
                    protocol : String? = nil, version : String? = nil,
                    headers : Hash(String, String)? = nil,
                    body : String? = nil) : self
      body_content = body ? ArtifactContent.new(text: body) : nil
      @web_request = WebRequest.new(
        target: target, method: method, protocol: protocol,
        version: version, headers: headers, body: body_content
      )
      self
    end

    def web_response(status_code : Int32, reason_phrase : String? = nil,
                     protocol : String? = nil, version : String? = nil,
                     headers : Hash(String, String)? = nil,
                     body : String? = nil) : self
      body_content = body ? ArtifactContent.new(text: body) : nil
      @web_response = WebResponse.new(
        status_code: status_code, reason_phrase: reason_phrase,
        protocol: protocol, version: version,
        headers: headers, body: body_content
      )
      self
    end

    def fingerprint(key : String, value : String) : self
      fp = @fingerprints ||= {} of String => String
      fp[key] = value
      self
    end

    def partial_fingerprint(key : String, value : String) : self
      pfp = @partial_fingerprints ||= {} of String => String
      pfp[key] = value
      self
    end

    def build(rules : Array(ReportingDescriptor)) : Result
      Result.new(
        message: Message.new(text: @text, markdown: @markdown),
        rule_id: @rule_id, level: @level, kind: @kind,
        rule_index: Sarif.find_rule_index(rules, @rule_id),
        locations: Sarif.nil_if_empty(@locations),
        related_locations: Sarif.nil_if_empty(@related_locations),
        code_flows: Sarif.nil_if_empty(@code_flows),
        fixes: Sarif.nil_if_empty(@fixes),
        suppressions: Sarif.nil_if_empty(@suppressions),
        stacks: Sarif.nil_if_empty(@stacks),
        graphs: Sarif.nil_if_empty(@graphs),
        fingerprints: @fingerprints,
        partial_fingerprints: @partial_fingerprints,
        web_request: @web_request,
        web_response: @web_response
      )
    end
  end

  class CodeFlowBuilder
    @message : String?
    @thread_flows = [] of ThreadFlow

    def initialize(@message : String? = nil)
    end

    def thread_flow(id : String? = nil, message : String? = nil, & : ThreadFlowBuilder ->) : self
      builder = ThreadFlowBuilder.new(id, message)
      yield builder
      @thread_flows << builder.build
      self
    end

    def build : CodeFlow
      msg = @message ? Message.new(text: @message) : nil
      CodeFlow.new(thread_flows: @thread_flows, message: msg)
    end
  end

  class ThreadFlowBuilder
    @id : String?
    @message : String?
    @locations = [] of ThreadFlowLocation

    def initialize(@id : String? = nil, @message : String? = nil)
    end

    def location(uri : String? = nil, start_line : Int32? = nil, message : String? = nil,
                 start_column : Int32? = nil, end_line : Int32? = nil,
                 end_column : Int32? = nil, importance : Importance? = nil,
                 nesting_level : Int32? = nil) : self
      loc = Sarif.build_location(uri: uri, start_line: start_line,
        start_column: start_column, end_line: end_line, end_column: end_column)
      if message
        loc = Location.new(physical_location: loc.physical_location,
          message: Message.new(text: message))
      end
      @locations << ThreadFlowLocation.new(
        location: loc, importance: importance, nesting_level: nesting_level
      )
      self
    end

    def build : ThreadFlow
      msg = @message ? Message.new(text: @message) : nil
      ThreadFlow.new(locations: @locations, id: @id, message: msg)
    end
  end

  class FixBuilder
    @description : String?
    @artifact_changes = [] of ArtifactChange

    def initialize(@description : String? = nil)
    end

    def artifact_change(uri : String, & : ArtifactChangeBuilder ->) : self
      builder = ArtifactChangeBuilder.new(uri)
      yield builder
      @artifact_changes << builder.build
      self
    end

    def build : Fix
      desc = @description ? Message.new(text: @description) : nil
      Fix.new(artifact_changes: @artifact_changes, description: desc)
    end
  end

  class ArtifactChangeBuilder
    @uri : String
    @replacements = [] of Replacement

    def initialize(@uri : String)
    end

    def replacement(start_line : Int32, start_column : Int32 = 1,
                    end_line : Int32? = nil, end_column : Int32? = nil,
                    inserted_text : String? = nil) : self
      deleted_region = Region.new(
        start_line: start_line, start_column: start_column,
        end_line: end_line || start_line, end_column: end_column
      )
      inserted_content = inserted_text ? ArtifactContent.new(text: inserted_text) : nil
      @replacements << Replacement.new(
        deleted_region: deleted_region, inserted_content: inserted_content
      )
      self
    end

    def build : ArtifactChange
      ArtifactChange.new(
        artifact_location: ArtifactLocation.new(uri: @uri),
        replacements: @replacements
      )
    end
  end

  class GraphBuilder
    @description : String?
    @nodes = [] of Node
    @edges = [] of Edge

    def initialize(@description : String? = nil)
    end

    def node(id : String, label : String? = nil, uri : String? = nil,
             start_line : Int32? = nil) : self
      loc = (uri || start_line) ? Sarif.build_location(uri: uri, start_line: start_line) : nil
      lbl = label ? Message.new(text: label) : nil
      @nodes << Node.new(id: id, label: lbl, location: loc)
      self
    end

    def edge(id : String, source_node_id : String, target_node_id : String,
             label : String? = nil) : self
      lbl = label ? Message.new(text: label) : nil
      @edges << Edge.new(id: id, source_node_id: source_node_id,
        target_node_id: target_node_id, label: lbl)
      self
    end

    def build : Graph
      desc = @description ? Message.new(text: @description) : nil
      Graph.new(
        description: desc,
        nodes: Sarif.nil_if_empty(@nodes),
        edges: Sarif.nil_if_empty(@edges)
      )
    end
  end

  class StackBuilder
    @message : String?
    @frames = [] of StackFrame

    def initialize(@message : String? = nil)
    end

    def frame(uri : String? = nil, start_line : Int32? = nil,
              module_name : String? = nil, thread_id : Int32? = nil,
              parameters : Array(String)? = nil) : self
      loc = (uri || start_line) ? Sarif.build_location(uri: uri, start_line: start_line) : nil
      @frames << StackFrame.new(location: loc, module_name: module_name,
        thread_id: thread_id, parameters: parameters)
      self
    end

    def build : Stack
      msg = @message ? Message.new(text: @message) : nil
      Stack.new(frames: @frames, message: msg)
    end
  end
end
