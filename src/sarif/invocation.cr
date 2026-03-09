require "json"

module Sarif
  class Invocation
    include JSON::Serializable

    @[JSON::Field(key: "executionSuccessful")]
    property execution_successful : Bool

    @[JSON::Field(key: "commandLine")]
    property command_line : String? = nil

    property arguments : Array(String)? = nil

    @[JSON::Field(key: "startTimeUtc")]
    property start_time_utc : String? = nil

    @[JSON::Field(key: "endTimeUtc")]
    property end_time_utc : String? = nil

    @[JSON::Field(key: "exitCode")]
    property exit_code : Int32? = nil

    @[JSON::Field(key: "exitCodeDescription")]
    property exit_code_description : String? = nil

    @[JSON::Field(key: "exitSignalName")]
    property exit_signal_name : String? = nil

    @[JSON::Field(key: "exitSignalNumber")]
    property exit_signal_number : Int32? = nil

    @[JSON::Field(key: "processStartFailureMessage")]
    property process_start_failure_message : String? = nil

    @[JSON::Field(key: "processId")]
    property process_id : Int32? = nil

    @[JSON::Field(key: "toolExecutionNotifications")]
    property tool_execution_notifications : Array(Notification)? = nil

    @[JSON::Field(key: "toolConfigurationNotifications")]
    property tool_configuration_notifications : Array(Notification)? = nil

    @[JSON::Field(key: "ruleConfigurationOverrides")]
    property rule_configuration_overrides : Array(ConfigurationOverride)? = nil

    @[JSON::Field(key: "notificationConfigurationOverrides")]
    property notification_configuration_overrides : Array(ConfigurationOverride)? = nil

    @[JSON::Field(key: "executableLocation")]
    property executable_location : ArtifactLocation? = nil

    @[JSON::Field(key: "workingDirectory")]
    property working_directory : ArtifactLocation? = nil

    @[JSON::Field(key: "environmentVariables")]
    property environment_variables : Hash(String, String)? = nil

    property account : String? = nil

    property machine : String? = nil

    @[JSON::Field(key: "responseFiles")]
    property response_files : Array(ArtifactLocation)? = nil

    @[JSON::Field(key: "stdin")]
    property stdin : ArtifactLocation? = nil

    @[JSON::Field(key: "stdout")]
    property stdout : ArtifactLocation? = nil

    @[JSON::Field(key: "stderr")]
    property stderr : ArtifactLocation? = nil

    @[JSON::Field(key: "stdoutStderr")]
    property stdout_stderr : ArtifactLocation? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@execution_successful : Bool, @command_line : String? = nil,
                   @arguments : Array(String)? = nil, @start_time_utc : String? = nil,
                   @end_time_utc : String? = nil, @exit_code : Int32? = nil,
                   @exit_code_description : String? = nil,
                   @exit_signal_name : String? = nil, @exit_signal_number : Int32? = nil,
                   @process_start_failure_message : String? = nil,
                   @process_id : Int32? = nil,
                   @tool_execution_notifications : Array(Notification)? = nil,
                   @tool_configuration_notifications : Array(Notification)? = nil,
                   @rule_configuration_overrides : Array(ConfigurationOverride)? = nil,
                   @notification_configuration_overrides : Array(ConfigurationOverride)? = nil,
                   @executable_location : ArtifactLocation? = nil,
                   @working_directory : ArtifactLocation? = nil,
                   @environment_variables : Hash(String, String)? = nil,
                   @account : String? = nil, @machine : String? = nil,
                   @response_files : Array(ArtifactLocation)? = nil,
                   @stdin : ArtifactLocation? = nil, @stdout : ArtifactLocation? = nil,
                   @stderr : ArtifactLocation? = nil, @stdout_stderr : ArtifactLocation? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
