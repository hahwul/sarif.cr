require "../spec_helper"

describe Sarif::Validator do
  it "validates a correct SARIF log" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "ValidTool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "Issue")),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
    result.errors.should be_empty
  end

  it "detects empty tool driver name" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: ""))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("name must not be empty")) }.should be_true
  end

  it "detects invalid version" do
    log = Sarif::SarifLog.new(
      version: "1.0.0",
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool"))
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Unsupported SARIF version")) }.should be_true
  end

  it "detects result message without text or id" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("text or id")) }.should be_true
  end

  it "detects invalid ruleIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(message: Sarif::Message.new(text: "issue"), rule_index: 5),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("Invalid ruleIndex")) }.should be_true
  end

  it "detects ruleId mismatch with ruleIndex" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "Tool",
              rules: [Sarif::ReportingDescriptor.new(id: "R001")]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              rule_id: "R999", rule_index: 0
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("does not match")) }.should be_true
  end

  it "detects invalid region startLine" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("startLine must be >= 1")) }.should be_true
  end

  it "detects invalid region startColumn" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 1, start_column: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("startColumn must be >= 1")) }.should be_true
  end

  it "detects endColumn < startColumn on same line" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 5, end_line: 5, start_column: 10, end_column: 3)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("endColumn")) }.should be_true
  end

  it "detects invalid region in relatedLocations" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              related_locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 0)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.path.includes?("relatedLocations") }.should be_true
  end

  it "detects endLine < startLine" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "Tool")),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "issue"),
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    region: Sarif::Region.new(start_line: 10, end_line: 5)
                  )
                ),
              ]
            ),
          ]
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_false
    result.errors.any? { |e| e.message.try(&.includes?("endLine")) }.should be_true
  end

  it "provides error path information" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(driver: Sarif::ToolComponent.new(name: "")),
        ),
      ]
    )
    result = Sarif::Validator.new.validate(log)
    result.errors[0].path.should eq("$.runs[0].tool.driver.name")
  end
end
