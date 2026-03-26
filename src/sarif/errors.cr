module Sarif
  # Base error class for all SARIF errors.
  class Error < Exception
  end

  # Represents a single validation error with a JSONPath-like path.
  class ValidationError < Error
    getter path : String

    def initialize(message : String, @path : String = "")
      super(message)
    end

    def to_s(io : IO) : Nil
      if @path.empty?
        io << message
      else
        io << @path << ": " << message
      end
    end
  end

  # Raised when `parse!` encounters validation errors.
  class ParseError < Error
    getter validation_errors : Array(ValidationError)

    def initialize(@validation_errors : Array(ValidationError))
      messages = @validation_errors.map(&.to_s).join("; ")
      super("SARIF validation failed: #{messages}")
    end
  end

  # The result of validating a SARIF document. Check `#valid?` and `#errors`.
  class ValidationResult
    getter errors : Array(ValidationError)

    def initialize(@errors : Array(ValidationError) = [] of ValidationError)
    end

    def valid? : Bool
      @errors.empty?
    end
  end
end
