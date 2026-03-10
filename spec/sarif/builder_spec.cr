require "../spec_helper"

describe Sarif::Builder do
  it "builds a minimal SARIF log" do
    log = Sarif::Builder.build do |b|
      b.run("MyTool") { }
    end
    log.version.should eq("2.1.0")
    log.runs.size.should eq(1)
    log.runs[0].tool.driver.name.should eq("MyTool")
  end

  it "builds with version" do
    log = Sarif::Builder.build do |b|
      b.run("MyTool", "1.0.0") { }
    end
    log.runs[0].tool.driver.version.should eq("1.0.0")
  end

  it "builds with results" do
    log = Sarif::Builder.build do |b|
      b.run("Linter", "1.0") do |r|
        r.result("Unused variable", rule_id: "LINT001",
          level: Sarif::Level::Warning, uri: "src/main.cr", start_line: 10)
      end
    end
    results = log.runs[0].results.not_nil!
    results.size.should eq(1)
    results[0].message.text.should eq("Unused variable")
    results[0].rule_id.should eq("LINT001")
    results[0].level.should eq(Sarif::Level::Warning)
    results[0].locations.not_nil![0].physical_location.not_nil!
      .artifact_location.not_nil!.uri.should eq("src/main.cr")
    results[0].locations.not_nil![0].physical_location.not_nil!
      .region.not_nil!.start_line.should eq(10)
  end

  it "builds with rules and auto-links ruleIndex" do
    log = Sarif::Builder.build do |b|
      b.run("Linter") do |r|
        r.rule("R001", name: "NoUnused", short_description: "No unused vars")
        r.rule("R002", name: "NoShadow", short_description: "No shadowed vars")
        r.result("Unused var", rule_id: "R001", level: Sarif::Level::Warning)
        r.result("Shadowed var", rule_id: "R002", level: Sarif::Level::Error)
      end
    end
    rules = log.runs[0].tool.driver.rules.not_nil!
    rules.size.should eq(2)
    rules[0].id.should eq("R001")
    rules[1].id.should eq("R002")

    results = log.runs[0].results.not_nil!
    results[0].rule_index.should eq(0)
    results[1].rule_index.should eq(1)
  end

  it "builds with ResultBuilder block" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Complex issue", markdown: "**Complex** issue")
          rb.rule_id("R1")
          rb.level(Sarif::Level::Error)
          rb.location(uri: "file.cr", start_line: 5, end_line: 10)
          rb.fingerprint("primary", "hash123")
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.message.text.should eq("Complex issue")
    result.message.markdown.should eq("**Complex** issue")
    result.rule_id.should eq("R1")
    result.level.should eq(Sarif::Level::Error)
    result.locations.not_nil!.size.should eq(1)
    result.fingerprints.not_nil!["primary"].should eq("hash123")
  end

  it "builds with artifacts" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.artifact("src/main.cr", mime_type: "text/x-crystal")
      end
    end
    artifacts = log.runs[0].artifacts.not_nil!
    artifacts.size.should eq(1)
    artifacts[0].location.not_nil!.uri.should eq("src/main.cr")
    artifacts[0].mime_type.should eq("text/x-crystal")
  end

  it "builds with invocations" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.invocation(true, "tool --check .")
      end
    end
    invocations = log.runs[0].invocations.not_nil!
    invocations.size.should eq(1)
    invocations[0].execution_successful.should be_true
    invocations[0].command_line.should eq("tool --check .")
  end

  it "builds multiple runs" do
    log = Sarif::Builder.build do |b|
      b.run("Tool1") { |r| r.result("Issue 1") }
      b.run("Tool2") { |r| r.result("Issue 2") }
    end
    log.runs.size.should eq(2)
    log.runs[0].tool.driver.name.should eq("Tool1")
    log.runs[1].tool.driver.name.should eq("Tool2")
  end

  it "produces valid JSON output" do
    log = Sarif::Builder.build do |b|
      b.run("MyLinter", "1.0.0") do |r|
        r.result("Unused variable", rule_id: "LINT001",
          level: Sarif::Level::Warning, uri: "src/main.cr", start_line: 10)
      end
    end
    json = log.to_pretty_json
    parsed = JSON.parse(json)
    parsed["version"].as_s.should eq("2.1.0")
    parsed["$schema"].as_s.should contain("sarif-schema")
    parsed["runs"][0]["tool"]["driver"]["name"].as_s.should eq("MyLinter")
  end
end
