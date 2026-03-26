require "../spec_helper"

describe Sarif::Conversion do
  it "creates with tool" do
    conv = Sarif::Conversion.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Converter"))
    )
    conv.tool.driver.name.should eq("Converter")
    conv.invocation.should be_nil
    conv.analysis_tool_log_files.should be_nil
  end

  it "creates with invocation" do
    conv = Sarif::Conversion.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Converter")),
      invocation: Sarif::Invocation.new(
        execution_successful: true,
        command_line: "convert input.log"
      )
    )
    conv.invocation.not_nil!.execution_successful.should be_true
    conv.invocation.not_nil!.command_line.should eq("convert input.log")
  end

  it "supports analysis tool log files" do
    conv = Sarif::Conversion.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Conv")),
      analysis_tool_log_files: [
        Sarif::ArtifactLocation.new(uri: "output.log"),
        Sarif::ArtifactLocation.new(uri: "debug.log"),
      ]
    )
    json = conv.to_json
    parsed = JSON.parse(json)
    parsed["analysisToolLogFiles"].as_a.size.should eq(2)
    parsed["analysisToolLogFiles"][0]["uri"].as_s.should eq("output.log")
  end

  it "round-trips through JSON" do
    conv = Sarif::Conversion.new(
      tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "MyConverter", version: "1.0")),
      invocation: Sarif::Invocation.new(execution_successful: true),
      analysis_tool_log_files: [Sarif::ArtifactLocation.new(uri: "input.sarif")]
    )
    restored = Sarif::Conversion.from_json(conv.to_json)
    restored.tool.driver.name.should eq("MyConverter")
    restored.invocation.not_nil!.execution_successful.should be_true
    restored.analysis_tool_log_files.not_nil![0].uri.should eq("input.sarif")
  end
end
