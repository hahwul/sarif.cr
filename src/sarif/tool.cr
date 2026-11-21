require "json"

module Sarif
  # Describes the analysis tool that produced a set of results.
  #
  # See: [SARIF 2.1.0 §3.18](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html#_Toc34317529)
  class Tool
    include JSON::Serializable

    @[JSON::Field(presence: true)]
    @driver : ToolComponent?

    @[JSON::Field(ignore: true)]
    @driver_present = false

    property extensions : Array(ToolComponent)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@driver : ToolComponent, @extensions : Array(ToolComponent)? = nil,
                   @properties : PropertyBag? = nil)
    end

    # The primary tool component. Resolve external properties before accessing
    # a driver stored outside the run's tool object (§3.15.3).
    def driver : ToolComponent
      @driver || raise Error.new("Resolve external properties before accessing the tool driver")
    end

    # Returns nil while the external driver is unresolved.
    def driver? : ToolComponent?
      @driver
    end

    def driver=(@driver : ToolComponent)
    end

    def self.new(pull : JSON::PullParser)
      new(pull, allow_external_driver: false)
    end

    # :nodoc:
    def self.new(pull : JSON::PullParser, *, allow_external_driver : Bool)
      line, column = pull.location_i64
      tool = new_from_json_pull_parser(pull)
      if tool.driver?.nil? && (!allow_external_driver || tool.@driver_present)
        message = tool.@driver_present ? "Tool driver must be an object" : "Missing JSON attribute: driver"
        raise JSON::SerializableError.new(message, to_s, "driver", line, column, nil)
      end
      tool
    end

    # :nodoc:
    module RunConverter
      def self.from_json(pull : JSON::PullParser) : Tool
        Tool.new(pull, allow_external_driver: true)
      end

      def self.to_json(tool : Tool, json : JSON::Builder) : Nil
        tool.to_json(json)
      end
    end
  end
end
