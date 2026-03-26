require "../spec_helper"

describe Sarif::Invocation do
  it "creates with execution_successful" do
    inv = Sarif::Invocation.new(execution_successful: true)
    inv.execution_successful.should be_true
    inv.command_line.should be_nil
    inv.arguments.should be_nil
  end

  it "creates with full details" do
    inv = Sarif::Invocation.new(
      execution_successful: true,
      command_line: "crystal build src/main.cr",
      arguments: ["build", "src/main.cr"],
      start_time_utc: "2024-01-01T10:00:00Z",
      end_time_utc: "2024-01-01T10:05:00Z",
      exit_code: 0,
      machine: "ci-runner-01",
      account: "build-user",
      process_id: 12345
    )
    inv.command_line.should eq("crystal build src/main.cr")
    inv.arguments.should eq(["build", "src/main.cr"])
    inv.exit_code.should eq(0)
    inv.machine.should eq("ci-runner-01")
    inv.process_id.should eq(12345)
  end

  it "serializes with camelCase keys" do
    inv = Sarif::Invocation.new(
      execution_successful: false,
      command_line: "tool run",
      start_time_utc: "2024-01-01T10:00:00Z",
      end_time_utc: "2024-01-01T10:01:00Z",
      exit_code: 1,
      exit_code_description: "Analysis failed",
      process_id: 999
    )
    json = inv.to_json
    parsed = JSON.parse(json)
    parsed["executionSuccessful"].as_bool.should be_false
    parsed["commandLine"].as_s.should eq("tool run")
    parsed["startTimeUtc"].as_s.should eq("2024-01-01T10:00:00Z")
    parsed["endTimeUtc"].as_s.should eq("2024-01-01T10:01:00Z")
    parsed["exitCode"].as_i.should eq(1)
    parsed["exitCodeDescription"].as_s.should eq("Analysis failed")
    parsed["processId"].as_i.should eq(999)
  end

  it "supports working directory and executable location" do
    inv = Sarif::Invocation.new(
      execution_successful: true,
      executable_location: Sarif::ArtifactLocation.new(uri: "/usr/bin/tool"),
      working_directory: Sarif::ArtifactLocation.new(uri: "file:///home/user/project")
    )
    json = inv.to_json
    parsed = JSON.parse(json)
    parsed["executableLocation"]["uri"].as_s.should eq("/usr/bin/tool")
    parsed["workingDirectory"]["uri"].as_s.should eq("file:///home/user/project")
  end

  it "supports environment variables" do
    inv = Sarif::Invocation.new(
      execution_successful: true,
      environment_variables: {"PATH" => "/usr/bin", "HOME" => "/home/user"}
    )
    json = inv.to_json
    parsed = JSON.parse(json)
    parsed["environmentVariables"]["PATH"].as_s.should eq("/usr/bin")
  end

  it "supports exit signal" do
    inv = Sarif::Invocation.new(
      execution_successful: false,
      exit_signal_name: "SIGSEGV",
      exit_signal_number: 11
    )
    json = inv.to_json
    parsed = JSON.parse(json)
    parsed["exitSignalName"].as_s.should eq("SIGSEGV")
    parsed["exitSignalNumber"].as_i.should eq(11)
  end

  it "round-trips through JSON" do
    inv = Sarif::Invocation.new(
      execution_successful: true,
      command_line: "analyzer --all",
      arguments: ["--all"],
      start_time_utc: "2024-06-01T00:00:00Z",
      end_time_utc: "2024-06-01T00:01:00Z",
      exit_code: 0,
      machine: "host1",
      account: "user1",
      process_id: 42
    )
    restored = Sarif::Invocation.from_json(inv.to_json)
    restored.execution_successful.should be_true
    restored.command_line.should eq("analyzer --all")
    restored.arguments.should eq(["--all"])
    restored.exit_code.should eq(0)
    restored.machine.should eq("host1")
    restored.process_id.should eq(42)
  end
end
