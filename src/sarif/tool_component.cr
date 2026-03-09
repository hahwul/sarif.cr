require "json"

module Sarif
  class ToolComponent
    include JSON::Serializable

    property name : String

    property version : String? = nil

    property guid : String? = nil

    @[JSON::Field(key: "semanticVersion")]
    property semantic_version : String? = nil

    @[JSON::Field(key: "dottedQuadFileVersion")]
    property dotted_quad_file_version : String? = nil

    @[JSON::Field(key: "releaseDateUtc")]
    property release_date_utc : String? = nil

    @[JSON::Field(key: "downloadUri")]
    property download_uri : String? = nil

    @[JSON::Field(key: "informationUri")]
    property information_uri : String? = nil

    @[JSON::Field(key: "organization")]
    property organization : String? = nil

    property product : String? = nil

    @[JSON::Field(key: "productSuite")]
    property product_suite : String? = nil

    @[JSON::Field(key: "shortDescription")]
    property short_description : MultiformatMessageString? = nil

    @[JSON::Field(key: "fullDescription")]
    property full_description : MultiformatMessageString? = nil

    @[JSON::Field(key: "fullName")]
    property full_name : String? = nil

    property language : String? = nil

    @[JSON::Field(key: "globalMessageStrings")]
    property global_message_strings : Hash(String, MultiformatMessageString)? = nil

    property rules : Array(ReportingDescriptor)? = nil

    property notifications : Array(ReportingDescriptor)? = nil

    property taxa : Array(ReportingDescriptor)? = nil

    property contents : Array(ToolComponentContent)? = nil

    @[JSON::Field(key: "isComprehensive")]
    property is_comprehensive : Bool? = nil

    @[JSON::Field(key: "localizedDataSemanticVersion")]
    property localized_data_semantic_version : String? = nil

    @[JSON::Field(key: "minimumRequiredLocalizedDataSemanticVersion")]
    property minimum_required_localized_data_semantic_version : String? = nil

    @[JSON::Field(key: "associatedComponent")]
    property associated_component : ToolComponentReference? = nil

    @[JSON::Field(key: "translationMetadata")]
    property translation_metadata : TranslationMetadata? = nil

    @[JSON::Field(key: "supportedTaxonomies")]
    property supported_taxonomies : Array(ToolComponentReference)? = nil

    property locations : Array(ArtifactLocation)? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@name : String, @version : String? = nil, @guid : String? = nil,
                   @semantic_version : String? = nil, @organization : String? = nil,
                   @product : String? = nil, @full_name : String? = nil,
                   @short_description : MultiformatMessageString? = nil,
                   @full_description : MultiformatMessageString? = nil,
                   @language : String? = nil,
                   @rules : Array(ReportingDescriptor)? = nil,
                   @notifications : Array(ReportingDescriptor)? = nil,
                   @taxa : Array(ReportingDescriptor)? = nil,
                   @contents : Array(ToolComponentContent)? = nil,
                   @information_uri : String? = nil,
                   @download_uri : String? = nil,
                   @dotted_quad_file_version : String? = nil,
                   @release_date_utc : String? = nil,
                   @product_suite : String? = nil,
                   @is_comprehensive : Bool? = nil,
                   @localized_data_semantic_version : String? = nil,
                   @minimum_required_localized_data_semantic_version : String? = nil,
                   @associated_component : ToolComponentReference? = nil,
                   @translation_metadata : TranslationMetadata? = nil,
                   @supported_taxonomies : Array(ToolComponentReference)? = nil,
                   @global_message_strings : Hash(String, MultiformatMessageString)? = nil,
                   @locations : Array(ArtifactLocation)? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
