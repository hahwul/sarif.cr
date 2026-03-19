module Sarif
  DEFAULT_MAX_INPUT_SIZE = 100 * 1024 * 1024 # 100 MB

  def self.parse(json : String, *, max_size : Int64? = nil) : SarifLog
    if limit = max_size
      if json.bytesize > limit
        raise Error.new("Input size #{json.bytesize} bytes exceeds maximum allowed size of #{limit} bytes")
      end
    end
    SarifLog.from_json(json)
  end

  def self.parse(io : IO, *, max_size : Int64? = nil) : SarifLog
    if limit = max_size
      json = io.gets_to_end
      if json.bytesize > limit
        raise Error.new("Input size #{json.bytesize} bytes exceeds maximum allowed size of #{limit} bytes")
      end
      SarifLog.from_json(json)
    else
      SarifLog.from_json(io)
    end
  end

  def self.from_file(path : String, *, max_size : Int64? = nil) : SarifLog
    if limit = max_size
      file_size = File.size(path)
      if file_size > limit
        raise Error.new("File size #{file_size} bytes exceeds maximum allowed size of #{limit} bytes")
      end
    end
    File.open(path) { |io| SarifLog.from_json(io) }
  end

  def self.parse!(json : String, *, max_size : Int64? = nil) : SarifLog
    log = parse(json, max_size: max_size)
    validate!(log)
  end

  def self.parse!(io : IO, *, max_size : Int64? = nil) : SarifLog
    log = parse(io, max_size: max_size)
    validate!(log)
  end

  def self.from_file!(path : String, *, max_size : Int64? = nil) : SarifLog
    log = from_file(path, max_size: max_size)
    validate!(log)
  end

  private def self.validate!(log : SarifLog) : SarifLog
    result = Validator.new.validate(log)
    raise ParseError.new(result.errors) unless result.valid?
    log
  end
end
