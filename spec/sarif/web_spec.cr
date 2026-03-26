require "../spec_helper"

describe Sarif::WebRequest do
  it "creates with defaults" do
    req = Sarif::WebRequest.new
    req.method.should be_nil
    req.target.should be_nil
    req.protocol.should be_nil
    req.headers.should be_nil
  end

  it "creates with full details" do
    req = Sarif::WebRequest.new(
      method: "POST",
      target: "/api/users",
      protocol: "HTTP",
      version: "1.1",
      headers: {"Content-Type" => "application/json", "Authorization" => "Bearer token"},
      parameters: {"page" => "1"},
      body: Sarif::ArtifactContent.new(text: "{\"name\":\"test\"}")
    )
    req.method.should eq("POST")
    req.target.should eq("/api/users")
    req.protocol.should eq("HTTP")
    req.version.should eq("1.1")
    req.headers.not_nil!["Content-Type"].should eq("application/json")
    req.parameters.not_nil!["page"].should eq("1")
    req.body.not_nil!.text.should eq("{\"name\":\"test\"}")
  end

  it "round-trips through JSON" do
    req = Sarif::WebRequest.new(
      index: 0,
      method: "GET",
      target: "/api/data",
      protocol: "HTTP",
      version: "2.0",
      headers: {"Accept" => "text/html"}
    )
    restored = Sarif::WebRequest.from_json(req.to_json)
    restored.index.should eq(0)
    restored.method.should eq("GET")
    restored.target.should eq("/api/data")
    restored.version.should eq("2.0")
    restored.headers.not_nil!["Accept"].should eq("text/html")
  end
end

describe Sarif::WebResponse do
  it "creates with defaults" do
    resp = Sarif::WebResponse.new
    resp.status_code.should be_nil
    resp.reason_phrase.should be_nil
    resp.no_response_received.should be_nil
  end

  it "creates with full details" do
    resp = Sarif::WebResponse.new(
      index: 0,
      protocol: "HTTP",
      version: "1.1",
      status_code: 200,
      reason_phrase: "OK",
      headers: {"Content-Type" => "application/json"},
      body: Sarif::ArtifactContent.new(text: "{\"status\":\"ok\"}")
    )
    resp.status_code.should eq(200)
    resp.reason_phrase.should eq("OK")
    resp.body.not_nil!.text.should eq("{\"status\":\"ok\"}")
  end

  it "serializes with camelCase keys" do
    resp = Sarif::WebResponse.new(
      status_code: 404,
      reason_phrase: "Not Found",
      no_response_received: false
    )
    json = resp.to_json
    parsed = JSON.parse(json)
    parsed["statusCode"].as_i.should eq(404)
    parsed["reasonPhrase"].as_s.should eq("Not Found")
    parsed["noResponseReceived"].as_bool.should be_false
  end

  it "supports no_response_received" do
    resp = Sarif::WebResponse.new(no_response_received: true)
    resp.no_response_received.should be_true
  end

  it "round-trips through JSON" do
    resp = Sarif::WebResponse.new(
      index: 1,
      protocol: "HTTP",
      version: "1.1",
      status_code: 500,
      reason_phrase: "Internal Server Error",
      headers: {"X-Request-Id" => "abc123"},
      body: Sarif::ArtifactContent.new(text: "error")
    )
    restored = Sarif::WebResponse.from_json(resp.to_json)
    restored.index.should eq(1)
    restored.status_code.should eq(500)
    restored.reason_phrase.should eq("Internal Server Error")
    restored.headers.not_nil!["X-Request-Id"].should eq("abc123")
    restored.body.not_nil!.text.should eq("error")
  end
end
