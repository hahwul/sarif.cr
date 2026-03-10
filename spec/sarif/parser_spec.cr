require "../spec_helper"

describe "Sarif.parse" do
  it "parses minimal SARIF JSON" do
    json = %({
      "version": "2.1.0",
      "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
      "runs": [
        {
          "tool": {
            "driver": {
              "name": "TestTool"
            }
          }
        }
      ]
    })
    log = Sarif.parse(json)
    log.version.should eq("2.1.0")
    log.runs.size.should eq(1)
    log.runs[0].tool.driver.name.should eq("TestTool")
  end

  it "parses SARIF with results" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "Linter" } },
        "results": [{
          "message": { "text": "Issue found" },
          "ruleId": "R001",
          "level": "error",
          "locations": [{
            "physicalLocation": {
              "artifactLocation": { "uri": "src/main.cr" },
              "region": { "startLine": 10, "startColumn": 5 }
            }
          }]
        }]
      }]
    })
    log = Sarif.parse(json)
    result = log.runs[0].results.not_nil![0]
    result.rule_id.should eq("R001")
    result.level.should eq(Sarif::Level::Error)
    result.locations.not_nil![0].physical_location.not_nil!
      .artifact_location.not_nil!.uri.should eq("src/main.cr")
    result.locations.not_nil![0].physical_location.not_nil!
      .region.not_nil!.start_line.should eq(10)
  end

  it "parses with camelCase field mapping" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "Tool", "informationUri": "https://example.com" } },
        "columnKind": "utf16CodeUnits",
        "defaultEncoding": "utf-8"
      }]
    })
    log = Sarif.parse(json)
    log.runs[0].tool.driver.information_uri.should eq("https://example.com")
    log.runs[0].column_kind.should eq(Sarif::ColumnKind::Utf16CodeUnits)
    log.runs[0].default_encoding.should eq("utf-8")
  end
end

describe "Sarif.parse!" do
  it "succeeds for valid SARIF" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "ValidTool" } },
        "results": [{
          "message": { "text": "Valid issue" },
          "ruleId": "R1"
        }]
      }]
    })
    log = Sarif.parse!(json)
    log.runs[0].tool.driver.name.should eq("ValidTool")
  end

  it "raises for empty tool name" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "" } }
      }]
    })
    expect_raises(Sarif::ParseError, /validation failed/) do
      Sarif.parse!(json)
    end
  end

  it "provides access to validation errors via ParseError" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "" } }
      }]
    })
    begin
      Sarif.parse!(json)
      fail "Expected ParseError"
    rescue ex : Sarif::ParseError
      ex.validation_errors.should_not be_empty
      ex.validation_errors[0].path.should eq("$.runs[0].tool.driver.name")
    end
  end
end

describe "Sarif.parse with IO" do
  it "parses SARIF from IO" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "IOTool" } }
      }]
    })
    io = IO::Memory.new(json)
    log = Sarif.parse(io)
    log.runs[0].tool.driver.name.should eq("IOTool")
  end
end

describe "Sarif.from_file" do
  it "reads and parses a SARIF file" do
    json = %({
      "version": "2.1.0",
      "runs": [{
        "tool": { "driver": { "name": "FileTool" } }
      }]
    })
    tmp = File.tempfile("sarif", ".json") do |f|
      f.print json
    end
    begin
      log = Sarif.from_file(tmp.path)
      log.runs[0].tool.driver.name.should eq("FileTool")
    ensure
      tmp.delete
    end
  end
end
