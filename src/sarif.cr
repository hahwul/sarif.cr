require "json"

module Sarif
  VERSION = "0.1.0"
end

# Errors and foundation
require "./sarif/errors"

# Enums and foundation
require "./sarif/enums"
require "./sarif/property_bag"
require "./sarif/multiformat_message_string"
require "./sarif/message"
require "./sarif/artifact_content"
require "./sarif/artifact_location"
require "./sarif/address"
require "./sarif/rectangle"
require "./sarif/region"
require "./sarif/physical_location"
require "./sarif/logical_location"
require "./sarif/location_relationship"
require "./sarif/location"

# Reporting descriptors and tool
require "./sarif/tool_component_reference"
require "./sarif/reporting_descriptor_reference"
require "./sarif/reporting_descriptor_relationship"
require "./sarif/reporting_configuration"
require "./sarif/reporting_descriptor"
require "./sarif/configuration_override"
require "./sarif/translation_metadata"
require "./sarif/tool_component"
require "./sarif/tool"

# Result supporting types
require "./sarif/suppression"
require "./sarif/result_provenance"
require "./sarif/stack_frame"
require "./sarif/stack"
require "./sarif/web_request"
require "./sarif/web_response"
require "./sarif/thread_flow_location"
require "./sarif/thread_flow"
require "./sarif/code_flow"
require "./sarif/node"
require "./sarif/edge"
require "./sarif/graph"
require "./sarif/edge_traversal"
require "./sarif/graph_traversal"
require "./sarif/replacement"
require "./sarif/artifact_change"
require "./sarif/fix"
require "./sarif/exception"
require "./sarif/notification"
require "./sarif/attachment"
require "./sarif/result"

# Run-level types
require "./sarif/artifact"
require "./sarif/invocation"
require "./sarif/conversion"
require "./sarif/version_control_details"
require "./sarif/run_automation_details"
require "./sarif/special_locations"
require "./sarif/external_property_file_reference"
require "./sarif/external_property_file_references"
require "./sarif/external_properties"
require "./sarif/run"
require "./sarif/sarif_log"

# User API
require "./sarif/builder"
require "./sarif/validator"
require "./sarif/parser"
