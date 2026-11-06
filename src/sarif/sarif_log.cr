require "json"

module Sarif
  # The SARIF version supported by this library.
  SARIF_VERSION = "2.1.0"

  # The default JSON schema URI for SARIF 2.1.0.
  SARIF_SCHEMA = "https://docs.oasis-open.org/sarif/sarif/v2.1.0/cos02/schemas/sarif-schema-2.1.0.json"

  # The root object of a SARIF log file.
  #
  # A `SarifLog` contains zero or more `Run` objects (or `null` runs when the tool failed to start), each representing
  # a single invocation of a static analysis tool.
  #
  # ```
  # log = Sarif::SarifLog.new(runs: [
  #   Sarif::Run.new(tool: Sarif::Tool.new(
  #     driver: Sarif::ToolComponent.new(name: "MyTool")
  #   )),
  # ])
  # puts log.to_pretty_json
  # ```
  #
  # See: [SARIF 2.1.0 §3.13](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317483)
  class SarifLog
    include JSON::Serializable

    property version : String

    @[JSON::Field(key: "$schema")]
    property schema : String? = nil

    # `null` when the tool failed to start or could not construct a run
    # (§3.13.4); `[]` when it ran but no runs were performed. The key is
    # always emitted, as `"runs": null` when nil. Use `#runs!` when a `null`
    # runs array is not acceptable to the caller.
    @[JSON::Field(emit_null: true, presence: true)]
    property runs : Array(Run)?

    @[JSON::Field(ignore: true)]
    @runs_present = false

    @[JSON::Field(key: "inlineExternalProperties")]
    property inline_external_properties : Array(ExternalProperties)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@runs : Array(Run)?, @version : String = SARIF_VERSION,
                   @schema : String? = SARIF_SCHEMA,
                   @inline_external_properties : Array(ExternalProperties)? = nil,
                   @properties : PropertyBag? = nil)
    end

    # `runs` is nilable but still required (§3.13.4): reject a missing key
    # while accepting an explicit `null`.
    protected def after_initialize
      unless @runs_present
        raise JSON::SerializableError.new("Missing JSON attribute: runs", self.class.to_s, "runs", 0, 0, nil)
      end
    end

    # Returns `runs`, raising `Sarif::Error` if it is `null` (the tool
    # failed to start, §3.13.4).
    def runs! : Array(Run)
      runs || raise Error.new("SarifLog runs is null (the tool failed to start)")
    end

    # Returns all results from all runs, flattened into a single array.
    def all_results : Array(Result)
      runs.try(&.flat_map { |run| run.results || [] of Result }) || [] of Result
    end

    # Returns results matching the given severity level across all runs.
    # The effective level is resolved against each result's own run so that
    # rule `defaultConfiguration.level` inheritance is honored.
    def results_by_level(level : Level) : Array(Result)
      matched = [] of Result
      runs.try &.each do |run|
        run.results.try &.each do |r|
          matched << r if r.effective_level(run) == level
        end
      end
      matched
    end

    # Returns results matching the given rule ID across all runs.
    def results_by_rule_id(rule_id : String) : Array(Result)
      all_results.select { |r| r.rule_id == rule_id }
    end

    # Filters results by multiple criteria simultaneously.
    # All provided criteria must match (AND logic). Omitted criteria are ignored.
    def find_results(rule_id : String? = nil, level : Level? = nil,
                     kind : ResultKind? = nil) : Array(Result)
      matched = [] of Result
      runs.try &.each do |run|
        run.results.try &.each do |r|
          next if rule_id && r.rule_id != rule_id
          next if level && r.effective_level(run) != level
          next if kind && r.effective_kind != kind
          matched << r
        end
      end
      matched
    end

    # Returns all locations that reference the given file URI across all results.
    def find_locations_in_file(uri : String) : Array(Location)
      locations = [] of Location
      all_results.each do |result|
        result.locations.try &.each do |loc|
          if physical = loc.physical_location
            if artifact_loc = physical.artifact_location
              locations << loc if artifact_loc.uri == uri
            end
          end
        end
      end
      locations
    end

    # Returns a hash mapping each severity level to the count of results at that level.
    def result_counts_by_level : Hash(Level, Int32)
      counts = {} of Level => Int32
      runs.try &.each do |run|
        run.results.try &.each do |r|
          lvl = r.effective_level(run)
          counts[lvl] = (counts[lvl]? || 0) + 1
        end
      end
      counts
    end

    # Returns a hash mapping each rule ID to the count of results for that rule.
    def result_counts_by_rule_id : Hash(String, Int32)
      counts = {} of String => Int32
      all_results.each do |r|
        if rid = r.rule_id
          counts[rid] = (counts[rid]? || 0) + 1
        end
      end
      counts
    end

    # Returns true if the log passes basic structural validation.
    # For comprehensive validation, use `Validator#validate`.
    def valid? : Bool
      return false unless version == SARIF_VERSION
      runs.try &.each do |run|
        return false unless run.valid?
      end
      true
    end
  end
end
