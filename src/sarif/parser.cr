module Sarif
  def self.parse(json : String) : SarifLog
    SarifLog.from_json(json)
  end

  def self.from_file(path : String) : SarifLog
    json = File.read(path)
    parse(json)
  end

  def self.parse!(json : String) : SarifLog
    log = parse(json)
    result = Validator.new.validate(log)
    unless result.valid?
      messages = result.errors.map(&.to_s).join("; ")
      raise "SARIF validation failed: #{messages}"
    end
    log
  end

  def self.from_file!(path : String) : SarifLog
    json = File.read(path)
    parse!(json)
  end
end
