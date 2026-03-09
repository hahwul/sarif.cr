require "json"

module Sarif
  class TranslationMetadata
    include JSON::Serializable

    property name : String

    @[JSON::Field(key: "fullName")]
    property full_name : String? = nil

    @[JSON::Field(key: "shortDescription")]
    property short_description : MultiformatMessageString? = nil

    @[JSON::Field(key: "fullDescription")]
    property full_description : MultiformatMessageString? = nil

    @[JSON::Field(key: "downloadUri")]
    property download_uri : String? = nil

    @[JSON::Field(key: "informationUri")]
    property information_uri : String? = nil

    @[JSON::Field(key: "properties")]
    property properties : PropertyBag? = nil

    def initialize(@name : String, @full_name : String? = nil,
                   @short_description : MultiformatMessageString? = nil,
                   @full_description : MultiformatMessageString? = nil,
                   @download_uri : String? = nil, @information_uri : String? = nil,
                   @properties : PropertyBag? = nil)
    end
  end
end
