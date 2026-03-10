module Sarif
  def self.parse(json : String) : SarifLog
    SarifLog.from_json(json)
  end

  def self.parse(io : IO) : SarifLog
    SarifLog.from_json(io)
  end

  def self.from_file(path : String) : SarifLog
    File.open(path) { |io| parse(io) }
  end

  def self.parse!(json : String) : SarifLog
    log = parse(json)
    validate!(log)
  end

  def self.parse!(io : IO) : SarifLog
    log = parse(io)
    validate!(log)
  end

  def self.from_file!(path : String) : SarifLog
    File.open(path) { |io| parse!(io) }
  end

  private def self.validate!(log : SarifLog) : SarifLog
    result = Validator.new.validate(log)
    raise ParseError.new(result.errors) unless result.valid?
    log
  end
end
