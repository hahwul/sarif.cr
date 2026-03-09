require "../spec_helper"

describe "SARIF Round-Trip" do
  it "round-trips a comprehensive SARIF document" do
    log = Sarif::SarifLog.new(
      runs: [
        Sarif::Run.new(
          tool: Sarif::Tool.new(
            driver: Sarif::ToolComponent.new(
              name: "SecurityScanner",
              version: "3.1.0",
              semantic_version: "3.1.0",
              information_uri: "https://example.com/scanner",
              rules: [
                Sarif::ReportingDescriptor.new(
                  id: "SEC001",
                  name: "SqlInjection",
                  short_description: Sarif::MultiformatMessageString.new(
                    text: "SQL Injection vulnerability"
                  ),
                  full_description: Sarif::MultiformatMessageString.new(
                    text: "A SQL injection vulnerability was detected.",
                    markdown: "A **SQL injection** vulnerability was detected."
                  ),
                  help_uri: "https://example.com/rules/SEC001",
                  default_configuration: Sarif::ReportingConfiguration.new(
                    level: Sarif::Level::Error, enabled: true
                  )
                ),
                Sarif::ReportingDescriptor.new(
                  id: "SEC002",
                  name: "XSS",
                  short_description: Sarif::MultiformatMessageString.new(
                    text: "Cross-site scripting"
                  ),
                  default_configuration: Sarif::ReportingConfiguration.new(
                    level: Sarif::Level::Warning
                  )
                ),
              ]
            )
          ),
          results: [
            Sarif::Result.new(
              message: Sarif::Message.new(text: "Possible SQL injection in query parameter"),
              rule_id: "SEC001",
              rule_index: 0,
              level: Sarif::Level::Error,
              kind: Sarif::ResultKind::Fail,
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    artifact_location: Sarif::ArtifactLocation.new(
                      uri: "src/controllers/user_controller.cr",
                      uri_base_id: "%SRCROOT%"
                    ),
                    region: Sarif::Region.new(
                      start_line: 42, start_column: 10,
                      end_line: 42, end_column: 55
                    )
                  )
                ),
              ],
              related_locations: [
                Sarif::Location.new(
                  id: 1,
                  physical_location: Sarif::PhysicalLocation.new(
                    artifact_location: Sarif::ArtifactLocation.new(uri: "src/db/query.cr"),
                    region: Sarif::Region.new(start_line: 15)
                  ),
                  message: Sarif::Message.new(text: "Query builder called here")
                ),
              ],
              fingerprints: {"primaryLocationLineHash" => "abc123"},
              partial_fingerprints: {"contextHash/v1" => "def456"},
              baseline_state: Sarif::BaselineState::New
            ),
            Sarif::Result.new(
              message: Sarif::Message.new(text: "Potential XSS in template"),
              rule_id: "SEC002",
              rule_index: 1,
              level: Sarif::Level::Warning,
              locations: [
                Sarif::Location.new(
                  physical_location: Sarif::PhysicalLocation.new(
                    artifact_location: Sarif::ArtifactLocation.new(uri: "src/views/index.ecr"),
                    region: Sarif::Region.new(start_line: 8, start_column: 5)
                  )
                ),
              ],
              suppressions: [
                Sarif::Suppression.new(
                  kind: Sarif::SuppressionKind::InSource,
                  status: Sarif::SuppressionStatus::Accepted,
                  justification: "Output is HTML-escaped"
                ),
              ]
            ),
          ],
          artifacts: [
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "src/controllers/user_controller.cr"),
              mime_type: "text/x-crystal",
              roles: [Sarif::ArtifactRole::AnalysisTarget],
              length: 2048_i64
            ),
            Sarif::Artifact.new(
              location: Sarif::ArtifactLocation.new(uri: "src/views/index.ecr"),
              roles: [Sarif::ArtifactRole::AnalysisTarget]
            ),
          ],
          invocations: [
            Sarif::Invocation.new(
              execution_successful: true,
              command_line: "scanner --check src/",
              start_time_utc: "2024-01-15T10:30:00Z",
              end_time_utc: "2024-01-15T10:30:05Z",
              exit_code: 1
            ),
          ],
          column_kind: Sarif::ColumnKind::Utf16CodeUnits,
          version_control_provenance: [
            Sarif::VersionControlDetails.new(
              repository_uri: "https://github.com/example/app",
              revision_id: "a1b2c3d4",
              branch: "main"
            ),
          ]
        ),
      ]
    )

    # Serialize
    json = log.to_json

    # Deserialize
    restored = Sarif::SarifLog.from_json(json)

    # Verify top-level
    restored.version.should eq("2.1.0")
    restored.runs.size.should eq(1)

    run = restored.runs[0]

    # Tool
    run.tool.driver.name.should eq("SecurityScanner")
    run.tool.driver.version.should eq("3.1.0")
    run.tool.driver.semantic_version.should eq("3.1.0")
    run.tool.driver.information_uri.should eq("https://example.com/scanner")
    run.tool.driver.rules.not_nil!.size.should eq(2)
    run.tool.driver.rules.not_nil![0].id.should eq("SEC001")
    run.tool.driver.rules.not_nil![0].default_configuration.not_nil!.level.should eq(Sarif::Level::Error)
    run.tool.driver.rules.not_nil![1].id.should eq("SEC002")

    # Results
    results = run.results.not_nil!
    results.size.should eq(2)

    r1 = results[0]
    r1.rule_id.should eq("SEC001")
    r1.rule_index.should eq(0)
    r1.level.should eq(Sarif::Level::Error)
    r1.kind.should eq(Sarif::ResultKind::Fail)
    r1.locations.not_nil![0].physical_location.not_nil!
      .artifact_location.not_nil!.uri.should eq("src/controllers/user_controller.cr")
    r1.locations.not_nil![0].physical_location.not_nil!
      .artifact_location.not_nil!.uri_base_id.should eq("%SRCROOT%")
    r1.related_locations.not_nil![0].id.should eq(1)
    r1.fingerprints.not_nil!["primaryLocationLineHash"].should eq("abc123")
    r1.baseline_state.should eq(Sarif::BaselineState::New)

    r2 = results[1]
    r2.rule_id.should eq("SEC002")
    r2.suppressions.not_nil![0].kind.should eq(Sarif::SuppressionKind::InSource)
    r2.suppressions.not_nil![0].status.should eq(Sarif::SuppressionStatus::Accepted)

    # Artifacts
    run.artifacts.not_nil!.size.should eq(2)
    run.artifacts.not_nil![0].mime_type.should eq("text/x-crystal")
    run.artifacts.not_nil![0].length.should eq(2048)

    # Invocations
    run.invocations.not_nil![0].execution_successful.should be_true
    run.invocations.not_nil![0].exit_code.should eq(1)

    # Run properties
    run.column_kind.should eq(Sarif::ColumnKind::Utf16CodeUnits)
    run.version_control_provenance.not_nil![0].branch.should eq("main")

    # Re-serialize should produce identical JSON
    json2 = restored.to_json
    json2.should eq(json)
  end

  it "round-trips a builder-generated document" do
    log = Sarif::Builder.build do |b|
      b.run("CrystalLint", "2.0.0") do |r|
        r.rule("CL001", name: "UnusedVar", short_description: "Unused variable detected")
        r.rule("CL002", name: "ShadowVar", short_description: "Variable shadows outer scope")
        r.result("Variable 'x' is never used", rule_id: "CL001",
                 level: Sarif::Level::Warning, uri: "src/app.cr", start_line: 15)
        r.result("Variable 'i' shadows outer 'i'", rule_id: "CL002",
                 level: Sarif::Level::Note, uri: "src/loop.cr", start_line: 22, start_column: 5)
        r.artifact("src/app.cr", mime_type: "text/x-crystal")
        r.artifact("src/loop.cr", mime_type: "text/x-crystal")
        r.invocation(true, "crystal-lint src/")
      end
    end

    json = log.to_json
    restored = Sarif::SarifLog.from_json(json)

    restored.version.should eq("2.1.0")
    restored.runs[0].tool.driver.name.should eq("CrystalLint")
    restored.runs[0].tool.driver.rules.not_nil!.size.should eq(2)
    restored.runs[0].results.not_nil!.size.should eq(2)
    restored.runs[0].artifacts.not_nil!.size.should eq(2)
    restored.runs[0].invocations.not_nil!.size.should eq(1)

    # Re-serialize
    json2 = restored.to_json
    json2.should eq(json)
  end

  it "round-trips a real-world-like ESLint SARIF output" do
    json = %({
      "version": "2.1.0",
      "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
      "runs": [{
        "tool": {
          "driver": {
            "name": "ESLint",
            "version": "8.0.0",
            "informationUri": "https://eslint.org",
            "rules": [{
              "id": "no-unused-vars",
              "shortDescription": { "text": "Disallow unused variables" },
              "helpUri": "https://eslint.org/docs/rules/no-unused-vars"
            }]
          }
        },
        "results": [{
          "ruleId": "no-unused-vars",
          "ruleIndex": 0,
          "level": "error",
          "message": { "text": "'x' is defined but never used." },
          "locations": [{
            "physicalLocation": {
              "artifactLocation": { "uri": "file:///project/src/index.js", "index": 0 },
              "region": { "startLine": 1, "startColumn": 5 }
            }
          }]
        }],
        "artifacts": [{
          "location": { "uri": "file:///project/src/index.js" }
        }]
      }]
    })

    log = Sarif.parse(json)
    log.runs[0].tool.driver.name.should eq("ESLint")
    log.runs[0].results.not_nil![0].rule_id.should eq("no-unused-vars")

    json2 = log.to_json
    restored = Sarif::SarifLog.from_json(json2)
    restored.runs[0].tool.driver.name.should eq("ESLint")
    restored.runs[0].results.not_nil![0].level.should eq(Sarif::Level::Error)
  end
end
