require "../spec_helper"

describe Sarif::Error do
  it "is a subclass of Exception" do
    error = Sarif::Error.new("something went wrong")
    error.should be_a(Exception)
    error.message.should eq("something went wrong")
  end
end

describe Sarif::ValidationError do
  it "creates with message only" do
    error = Sarif::ValidationError.new("missing field")
    error.message.should eq("missing field")
    error.path.should eq("")
  end

  it "creates with message and path" do
    error = Sarif::ValidationError.new("invalid value", path: "$.runs[0].tool")
    error.message.should eq("invalid value")
    error.path.should eq("$.runs[0].tool")
  end

  it "formats to_s with path" do
    error = Sarif::ValidationError.new("required", path: "$.version")
    error.to_s.should eq("$.version: required")
  end

  it "formats to_s without path" do
    error = Sarif::ValidationError.new("general error")
    error.to_s.should eq("general error")
  end
end

describe Sarif::ParseError do
  it "creates from validation errors" do
    errors = [
      Sarif::ValidationError.new("missing version", path: "$.version"),
      Sarif::ValidationError.new("missing runs", path: "$.runs"),
    ]
    parse_error = Sarif::ParseError.new(errors)
    parse_error.validation_errors.size.should eq(2)
    parse_error.message.not_nil!.should contain("SARIF validation failed")
    parse_error.message.not_nil!.should contain("missing version")
    parse_error.message.not_nil!.should contain("missing runs")
  end

  it "is a subclass of Sarif::Error" do
    parse_error = Sarif::ParseError.new([] of Sarif::ValidationError)
    parse_error.should be_a(Sarif::Error)
  end
end

describe Sarif::ValidationResult do
  it "is valid when no errors" do
    result = Sarif::ValidationResult.new
    result.valid?.should be_true
    result.errors.should be_empty
  end

  it "is invalid when errors present" do
    result = Sarif::ValidationResult.new(
      errors: [Sarif::ValidationError.new("bad field", path: "$.runs")]
    )
    result.valid?.should be_false
    result.errors.size.should eq(1)
  end

  it "reports multiple errors" do
    result = Sarif::ValidationResult.new(
      errors: [
        Sarif::ValidationError.new("error 1"),
        Sarif::ValidationError.new("error 2"),
        Sarif::ValidationError.new("error 3"),
      ]
    )
    result.valid?.should be_false
    result.errors.size.should eq(3)
  end
end
