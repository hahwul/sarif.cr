require "../spec_helper"

describe Sarif::ExternalProperties do
  it "resolves shared properties by pointer or GUID and appends split arrays in reference order" do
    source = Sarif.parse <<-JSON
      {"version":"2.1.0","inlineExternalProperties":[
        {"guid":"550e8400-e29b-41d4-a716-446655440000","results":[{"message":{"text":"second"}}],
         "artifacts":[{"location":{"uri":"shared.cr"}}]},
        {"results":[{"message":{"text":"third"}}],"externalizedProperties":{"team":"tools"}}
      ],"runs":[
        {"tool":{"driver":{"name":"T"}},"results":[{"message":{"text":"first"},"locations":[
          {"physicalLocation":{"artifactLocation":{"index":1}}}]}],
          "artifacts":[{"location":{"uri":"local.cr"}}],"externalPropertyFileReferences":{
            "results":[{"guid":"550E8400-E29B-41D4-A716-446655440000","itemCount":1},
              {"location":{"uri":"sarif:/inlineExternalProperties/1"}}],
            "artifacts":[{"location":{"uri":"sarif:/inlineExternalPropertyFiles/0"}}],
            "externalizedProperties":{"location":{"uri":"sarif:/inlineExternalProperties/1"}}
          }},
        {"tool":{"driver":{"name":"U"}},"externalPropertyFileReferences":{
          "artifacts":[{"guid":"550e8400-e29b-41d4-a716-446655440000"}]
        }}
      ]}
      JSON

    original_json = source.to_json
    Sarif::Validator.new.validate(source).valid?.should be_true
    resolved = source.resolve_external_properties
    resolved.all_results.map(&.message.text).should eq(%w(first second third))
    resolved.find_locations_in_file("shared.cr").size.should eq(1)
    resolved.runs![0].properties.not_nil!.get_string("team").should eq("tools")
    resolved.runs![1].artifacts.not_nil!.size.should eq(1)
    resolved.runs![0].external_property_file_references.should be_nil
    Sarif.parse!(resolved.to_json).all_results.size.should eq(3)
    resolved.resolve_external_properties.to_json.should eq(resolved.to_json)
    source.to_json.should eq(original_json)
  end

  it "uses the root URI and run URI base IDs for files and loads a shared file once" do
    source = Sarif.parse <<-JSON
      {"version":"2.1.0","runs":[
        {"tool":{"driver":{"name":"T"}},"originalUriBaseIds":{"PARTS":{"uri":"file:///reports/parts/"}},
         "externalPropertyFileReferences":{"results":[{"location":{"uri":"report.json","uriBaseId":"PARTS"}}],
          "extensions":[{"location":{"uri":"parts/report.json"}}]}}
      ]}
      JSON

    files = [] of String
    external = Sarif::ExternalProperties.from_json(<<-JSON)
      {"version":"2.1.0","extensions":[{"name":"plugin","rules":[{"id":"R"}]}],
       "results":[{"rule":{"index":0,"toolComponent":{"index":0}},"message":{"text":"from file"}}]}
      JSON
    resolved = source.resolve_external_properties(base_uri: "file:///reports/root.sarif") do |uri|
      files << uri
      external
    end
    files.should eq(["file:///reports/parts/report.json"])
    resolved.all_results.first.resolve_rule(resolved.runs!.first).not_nil!.id.should eq("R")
    Sarif::Validator.new.validate(resolved).valid?.should be_true
    source.runs!.first.tool.extensions.should be_nil
  end

  it "rejects missing files and checks the referenced field, GUID, version and count" do
    source = Sarif.parse <<-JSON
      {"version":"2.1.0","runs":[{"tool":{"driver":{"name":"T"}},
       "externalPropertyFileReferences":{"results":[{"guid":"550e8400-e29b-41d4-a716-446655440000",
        "location":{"uri":"part.sarif-external-properties"},"itemCount":1}]}}]}
      JSON
    expect_raises(Sarif::Error, /No external property file loader/) { source.resolve_external_properties }
    [
      { %({"version":"2.1.0","guid":"550e8400-e29b-41d4-a716-446655440000"}), /without results/ },
      { %({"version":"2.1.0","guid":"550e8400-e29b-41d4-a716-446655440000","results":[]}), /itemCount/ },
      { %({"version":"2.1.0","results":[]}), /GUID/ },
      { %({"guid":"550e8400-e29b-41d4-a716-446655440000","results":[]}), /require version/ },
    ].each do |json, message|
      before = source.to_json
      expect_raises(Sarif::Error, message) do
        source.resolve_external_properties { Sarif::ExternalProperties.from_json(json) }
      end
      source.to_json.should eq(before)
    end
  end

  it "rejects a duplicate reference reached through a pointer and GUID" do
    source = Sarif.parse <<-JSON
      {"version":"2.1.0","inlineExternalProperties":[{"guid":"550e8400-e29b-41d4-a716-446655440000","results":[]}],
       "runs":[{"tool":{"driver":{"name":"T"}},"externalPropertyFileReferences":{"results":[
        {"location":{"uri":"sarif:/inlineExternalProperties/0"}},{"guid":"550e8400-e29b-41d4-a716-446655440000"}]}}]}
      JSON
    expect_raises(Sarif::Error, /repeats the same external properties/) { source.resolve_external_properties }
  end
end
