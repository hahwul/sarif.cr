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

  it "builds with code_flows via ResultBuilder" do
    thread_flow = Sarif::ThreadFlow.new(
      locations: [
        Sarif::ThreadFlowLocation.new(
          location: Sarif::Location.new(
            physical_location: Sarif::PhysicalLocation.new(
              artifact_location: Sarif::ArtifactLocation.new(uri: "src/a.cr"),
              region: Sarif::Region.new(start_line: 1)
            )
          )
        ),
      ]
    )
    code_flow = Sarif::CodeFlow.new(thread_flows: [thread_flow])

    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Flow issue")
          rb.code_flow(code_flow)
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.code_flows.not_nil!.size.should eq(1)
  end

  it "builds with fixes via ResultBuilder" do
    fix = Sarif::Fix.new(
      artifact_changes: [
        Sarif::ArtifactChange.new(
          artifact_location: Sarif::ArtifactLocation.new(uri: "src/a.cr"),
          replacements: [
            Sarif::Replacement.new(
              deleted_region: Sarif::Region.new(start_line: 1, start_column: 1, end_line: 1, end_column: 5),
              inserted_content: Sarif::ArtifactContent.new(text: "fixed")
            ),
          ]
        ),
      ],
      description: Sarif::Message.new(text: "Apply fix")
    )

    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Fixable issue")
          rb.fix(fix)
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.fixes.not_nil!.size.should eq(1)
    result.fixes.not_nil![0].description.not_nil!.text.should eq("Apply fix")
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

  it "builds code_flow with DSL block" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Taint flow")
          rb.code_flow("Data flow") do |cf|
            cf.thread_flow do |tf|
              tf.location(uri: "src/input.cr", start_line: 5, message: "source")
              tf.location(uri: "src/process.cr", start_line: 20, message: "propagation")
              tf.location(uri: "src/output.cr", start_line: 42, message: "sink")
            end
          end
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    code_flows = result.code_flows.not_nil!
    code_flows.size.should eq(1)
    code_flows[0].message.not_nil!.text.should eq("Data flow")

    thread_flows = code_flows[0].thread_flows
    thread_flows.size.should eq(1)
    thread_flows[0].locations.size.should eq(3)
    thread_flows[0].locations[0].location.not_nil!.message.not_nil!.text.should eq("source")
    thread_flows[0].locations[1].location.not_nil!.physical_location.not_nil!
      .region.not_nil!.start_line.should eq(20)
    thread_flows[0].locations[2].location.not_nil!.message.not_nil!.text.should eq("sink")
  end

  it "builds fix with DSL block" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Fixable issue")
          rb.fix("Replace deprecated call") do |f|
            f.artifact_change("src/main.cr") do |ac|
              ac.replacement(start_line: 10, start_column: 5, end_column: 15, inserted_text: "new_method")
            end
          end
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    fixes = result.fixes.not_nil!
    fixes.size.should eq(1)
    fixes[0].description.not_nil!.text.should eq("Replace deprecated call")

    changes = fixes[0].artifact_changes
    changes.size.should eq(1)
    changes[0].artifact_location.uri.should eq("src/main.cr")
    changes[0].replacements.size.should eq(1)
    changes[0].replacements[0].deleted_region.start_line.should eq(10)
    changes[0].replacements[0].inserted_content.not_nil!.text.should eq("new_method")
  end

  it "builds suppression with DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Suppressed issue")
          rb.suppression(Sarif::SuppressionKind::InSource, justification: "false positive")
          rb.suppression(Sarif::SuppressionKind::External, status: Sarif::SuppressionStatus::Accepted)
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    suppressions = result.suppressions.not_nil!
    suppressions.size.should eq(2)
    suppressions[0].kind.should eq(Sarif::SuppressionKind::InSource)
    suppressions[0].justification.should eq("false positive")
    suppressions[1].kind.should eq(Sarif::SuppressionKind::External)
    suppressions[1].status.should eq(Sarif::SuppressionStatus::Accepted)
  end

  it "builds code_flow with multiple thread flows" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Multi-thread flow")
          rb.code_flow do |cf|
            cf.thread_flow(id: "thread-1") do |tf|
              tf.location(uri: "a.cr", start_line: 1, message: "step 1")
            end
            cf.thread_flow(id: "thread-2") do |tf|
              tf.location(uri: "b.cr", start_line: 2, message: "step 1")
            end
          end
        end
      end
    end
    code_flow = log.runs[0].results.not_nil![0].code_flows.not_nil![0]
    code_flow.thread_flows.size.should eq(2)
    code_flow.thread_flows[0].id.should eq("thread-1")
    code_flow.thread_flows[1].id.should eq("thread-2")
  end

  it "builds thread_flow location with importance and nesting_level" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("issue")
          rb.code_flow do |cf|
            cf.thread_flow do |tf|
              tf.location(uri: "a.cr", start_line: 1, importance: Sarif::Importance::Essential, nesting_level: 0)
              tf.location(uri: "a.cr", start_line: 5, importance: Sarif::Importance::Unimportant, nesting_level: 1)
            end
          end
        end
      end
    end
    locs = log.runs[0].results.not_nil![0].code_flows.not_nil![0].thread_flows[0].locations
    locs[0].importance.should eq(Sarif::Importance::Essential)
    locs[0].nesting_level.should eq(0)
    locs[1].importance.should eq(Sarif::Importance::Unimportant)
    locs[1].nesting_level.should eq(1)
  end

  it "sets nil ruleIndex when rule_id doesn't match any rule" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.rule("R001", name: "ExistingRule")
        r.result("Issue", rule_id: "NONEXISTENT", level: Sarif::Level::Warning)
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.rule_id.should eq("NONEXISTENT")
    result.rule_index.should be_nil
  end

  it "builds result without locations when no uri or line given" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result("No location")
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.locations.should be_nil
  end

  it "builds empty run with no results or artifacts" do
    log = Sarif::Builder.build do |b|
      b.run("EmptyTool") { }
    end
    run = log.runs[0]
    run.results.should be_nil
    run.artifacts.should be_nil
    run.invocations.should be_nil
    run.tool.driver.rules.should be_nil
  end

  it "validates built log passes validator" do
    log = Sarif::Builder.build do |b|
      b.run("Tool", "1.0") do |r|
        r.rule("R1", short_description: "Test rule")
        r.result("Issue found", rule_id: "R1", level: Sarif::Level::Warning,
          uri: "src/main.cr", start_line: 10)
      end
    end
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end

  # --- Graph builder ---

  it "builds graph with nodes and edges via DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.graph("Call graph") do |g|
          g.node("n1", label: "main", uri: "src/main.cr", start_line: 1)
          g.node("n2", label: "helper", uri: "src/helper.cr", start_line: 10)
          g.edge("e1", "n1", "n2", label: "calls")
        end
      end
    end
    graphs = log.runs[0].graphs.not_nil!
    graphs.size.should eq(1)
    graphs[0].description.not_nil!.text.should eq("Call graph")
    graphs[0].nodes.not_nil!.size.should eq(2)
    graphs[0].nodes.not_nil![0].id.should eq("n1")
    graphs[0].nodes.not_nil![0].label.not_nil!.text.should eq("main")
    graphs[0].edges.not_nil!.size.should eq(1)
    graphs[0].edges.not_nil![0].source_node_id.should eq("n1")
    graphs[0].edges.not_nil![0].target_node_id.should eq("n2")
  end

  it "builds graph on result via DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Graph result")
          rb.graph("Data flow") do |g|
            g.node("src", label: "source")
            g.node("sink", label: "sink")
            g.edge("flow", "src", "sink")
          end
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.graphs.not_nil!.size.should eq(1)
    result.graphs.not_nil![0].nodes.not_nil!.size.should eq(2)
  end

  # --- Stack builder ---

  it "builds stack with frames via DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("Crash detected")
          rb.stack("Exception stack") do |s|
            s.frame(uri: "src/main.cr", start_line: 42, module_name: "app")
            s.frame(uri: "src/lib.cr", start_line: 10, module_name: "lib")
          end
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    stacks = result.stacks.not_nil!
    stacks.size.should eq(1)
    stacks[0].message.not_nil!.text.should eq("Exception stack")
    stacks[0].frames.size.should eq(2)
    stacks[0].frames[0].location.not_nil!.physical_location.not_nil!
      .region.not_nil!.start_line.should eq(42)
    stacks[0].frames[0].module_name.should eq("app")
  end

  # --- VersionControlDetails builder ---

  it "builds version control provenance via DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.version_control(
          repository_uri: "https://github.com/example/repo",
          revision_id: "abc123",
          branch: "main",
          mapped_to: "/"
        )
      end
    end
    vcp = log.runs[0].version_control_provenance.not_nil!
    vcp.size.should eq(1)
    vcp[0].repository_uri.should eq("https://github.com/example/repo")
    vcp[0].revision_id.should eq("abc123")
    vcp[0].branch.should eq("main")
    vcp[0].mapped_to.not_nil!.uri.should eq("/")
  end

  it "builds multiple version control entries" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.version_control(repository_uri: "https://github.com/a/repo", branch: "main")
        r.version_control(repository_uri: "https://github.com/b/repo", revision_tag: "v1.0")
      end
    end
    vcp = log.runs[0].version_control_provenance.not_nil!
    vcp.size.should eq(2)
    vcp[1].revision_tag.should eq("v1.0")
  end

  # --- WebRequest/WebResponse builder ---

  it "builds web request on result via DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("HTTP issue")
          rb.web_request(
            target: "/api/users",
            method: "POST",
            protocol: "HTTP",
            version: "1.1",
            headers: {"Content-Type" => "application/json"},
            body: "{\"name\": \"test\"}"
          )
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    req = result.web_request.not_nil!
    req.target.should eq("/api/users")
    req.method.should eq("POST")
    req.protocol.should eq("HTTP")
    req.version.should eq("1.1")
    req.headers.not_nil!["Content-Type"].should eq("application/json")
    req.body.not_nil!.text.should eq("{\"name\": \"test\"}")
  end

  it "builds web response on result via DSL" do
    log = Sarif::Builder.build do |b|
      b.run("Tool") do |r|
        r.result do |rb|
          rb.message("HTTP issue")
          rb.web_response(
            status_code: 500,
            reason_phrase: "Internal Server Error",
            headers: {"Content-Type" => "text/plain"},
            body: "Error occurred"
          )
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    resp = result.web_response.not_nil!
    resp.status_code.should eq(500)
    resp.reason_phrase.should eq("Internal Server Error")
    resp.headers.not_nil!["Content-Type"].should eq("text/plain")
    resp.body.not_nil!.text.should eq("Error occurred")
  end

  it "builds result with both web request and response" do
    log = Sarif::Builder.build do |b|
      b.run("Scanner") do |r|
        r.result do |rb|
          rb.message("XSS vulnerability")
          rb.web_request(target: "/search?q=<script>", method: "GET")
          rb.web_response(status_code: 200, body: "<script>alert(1)</script>")
        end
      end
    end
    result = log.runs[0].results.not_nil![0]
    result.web_request.not_nil!.target.should eq("/search?q=<script>")
    result.web_response.not_nil!.status_code.should eq(200)
  end

  # --- Comprehensive builder + validator integration ---

  it "builds complex log that passes validation" do
    log = Sarif::Builder.build do |b|
      b.run("SecurityScanner", "2.0") do |r|
        r.version_control(
          repository_uri: "https://github.com/example/repo",
          revision_id: "abc123", branch: "main"
        )
        r.rule("SEC001", name: "XSS", short_description: "Cross-site scripting")
        r.graph("Call graph") do |g|
          g.node("entry", label: "entry point")
          g.node("sink", label: "sink")
          g.edge("flow", "entry", "sink")
        end
        r.result do |rb|
          rb.message("XSS found")
          rb.rule_id("SEC001")
          rb.level(Sarif::Level::Error)
          rb.location(uri: "src/web.cr", start_line: 42)
          rb.stack do |s|
            s.frame(uri: "src/web.cr", start_line: 42)
            s.frame(uri: "src/app.cr", start_line: 10)
          end
          rb.web_request(target: "/api", method: "GET")
          rb.web_response(status_code: 200)
        end
      end
    end
    result = Sarif::Validator.new.validate(log)
    result.valid?.should be_true
  end
end
