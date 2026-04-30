module Sarif
  # A conservative byte cap that callers parsing SARIF from an untrusted
  # source SHOULD pass via `max_size:`. 256 MiB is large enough for any
  # realistic enterprise SBOM/SARIF artifact while still bounding total
  # memory if a producer (or a hostile fixture) streams an unbounded
  # JSON document. The library does not apply this cap by default to
  # avoid surprising callers that legitimately ingest very large reports.
  DEFAULT_MAX_SIZE = 256_i64 * 1024 * 1024

  # Parses a SARIF JSON string into a `SarifLog`.
  # Pass `max_size` to reject inputs exceeding the byte limit.
  # Raises `Sarif::Error` on invalid JSON or size limit violations.
  #
  # Security: when parsing input from an untrusted producer, pass
  # `max_size: Sarif::DEFAULT_MAX_SIZE` (or a tighter cap) so a hostile
  # report cannot exhaust memory.
  def self.parse(json : String, *, max_size : Int64? = nil) : SarifLog
    check_size!(json.bytesize.to_i64, max_size, "Input")
    parse_json(json)
  rescue ex : Sarif::Error
    raise ex
  rescue ex : JSON::ParseException | JSON::SerializableError
    raise Error.new("Failed to parse SARIF JSON: #{ex.message}")
  end

  # Streams and parses a SARIF JSON document from the given IO.
  #
  # Security: with the default `max_size: nil` the IO is consumed
  # straight into `SarifLog.from_json` with no byte cap; callers that
  # cannot trust the producer SHOULD pass `max_size: Sarif::DEFAULT_MAX_SIZE`
  # so the IO is read into a buffer and rejected past the cap.
  def self.parse(io : IO, *, max_size : Int64? = nil) : SarifLog
    if max_size
      json = io.gets_to_end
      check_size!(json.bytesize.to_i64, max_size, "Input")
      parse_json(json)
    else
      parse_json(io)
    end
  rescue ex : Sarif::Error
    raise ex
  rescue ex : JSON::ParseException | JSON::SerializableError
    raise Error.new("Failed to parse SARIF JSON: #{ex.message}")
  end

  # Reads and parses a SARIF file from the given path.
  # Raises `Sarif::Error` if the file cannot be read or contains invalid JSON.
  #
  # Security: the file size check is opt-in. When parsing files produced
  # outside the caller's trust boundary (e.g. CI artifacts uploaded by
  # third parties), pass `max_size: Sarif::DEFAULT_MAX_SIZE`.
  def self.from_file(path : String, *, max_size : Int64? = nil) : SarifLog
    if max_size
      check_size!(File.size(path).to_i64, max_size, "File")
    end
    File.open(path) { |io| parse_json(io) }
  rescue ex : File::NotFoundError
    raise Error.new("File not found: #{path}")
  rescue ex : File::AccessDeniedError
    raise Error.new("Permission denied: #{path}")
  rescue ex : Sarif::Error
    raise ex
  rescue ex : JSON::ParseException | JSON::SerializableError
    raise Error.new("Failed to parse SARIF file '#{path}': #{ex.message}")
  end

  # Parses and validates a SARIF JSON string. Raises `ParseError` on validation failure.
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

  private def self.check_size!(actual : Int64, limit : Int64?, label : String = "Input") : Nil
    if limit && actual > limit
      raise Error.new("#{label} size #{actual} bytes exceeds maximum allowed size of #{limit} bytes")
    end
  end

  private def self.parse_json(input : String | IO) : SarifLog
    SarifLog.from_json(input)
  end

  private def self.validate!(log : SarifLog) : SarifLog
    result = Validator.new.validate(log)
    raise ParseError.new(result.errors) unless result.valid?
    log
  end
end
