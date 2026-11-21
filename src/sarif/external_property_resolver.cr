module Sarif
  private class ExternalPropertyResolver
    # The published §3.13.5 example uses inlineExternalPropertyFiles in its
    # pointer, while the actual property is named inlineExternalProperties.
    private INLINE_POINTER = %r{\A/(?:inlineExternalProperties|inlineExternalPropertyFiles)/(0|[1-9][0-9]*)\z}

    @inline_by_guid : Hash(String, Array(ExternalProperties))
    @loaded = {} of String => ExternalProperties

    def initialize(@inline : Array(ExternalProperties)?, @base_uri : String?,
                   @loader : Proc(String, ExternalProperties))
      @inline_by_guid = (@inline || [] of ExternalProperties).select(&.guid).group_by { |entry| entry.guid.not_nil!.downcase }
    end

    def resolve(source : Run, path : String) : Run
      run = source.dup
      return run unless refs = source.external_property_file_references
      path = "#{path}.externalPropertyFileReferences"
      run.tool = source.tool.dup

      {% for property in %w(artifacts addresses graphs invocations logical_locations policies results taxonomies thread_flow_locations translations web_requests web_responses extensions) %}
        if references = refs.{{property.id}}
          field_path = "#{path}." + {{property.camelcase(lower: true)}}
          {% owner = property == "extensions" ? "run.tool".id : "run".id %}
          entries = {{owner}}.{{property.id}}.try(&.dup)
          seen = Set(String | ExternalProperties).new
          references.each_with_index do |ref, i|
            ref_path = "#{field_path}[#{i}]"
            external = load(ref, run, ref_path)
            unless seen.add?(external.guid.try(&.downcase) || external)
              raise Error.new("#{ref_path} repeats the same external properties")
            end
            values = external.{{property.id}}
            unless values
              raise Error.new("#{ref_path} points to a document without " + {{property.camelcase(lower: true)}})
            end
            if (count = ref.item_count) && count != -1 && count != values.size
              raise Error.new("#{ref_path}.itemCount is #{count}, but the external array contains #{values.size} item(s)")
            end
            entries = entries ? entries.concat(values) : values.dup
          end
          {{owner}}.{{property.id}} = entries
        end
      {% end %}

      {% for property, target in {conversion: "run.conversion", externalized_properties: "run.properties", driver: "run.tool.driver"} %}
        if ref = refs.{{property.id}}
          field_path = "#{path}." + {{property.stringify.camelcase(lower: true)}}
          if ref.item_count
            raise Error.new("#{field_path}.itemCount must be absent for an object-valued property")
          end
          external = load(ref, run, field_path)
          value = external.{{property.id}} || raise Error.new("#{field_path} points to a document without " + {{property.stringify.camelcase(lower: true)}})
          {{target.id}} = value
        end
      {% end %}

      run.external_property_file_references = nil
      run
    end

    private def load(ref : ExternalPropertyFileReference, run : Run, path : String) : ExternalProperties
      external_file = false
      if location = ref.location
        uri = run.resolve_artifact_uri(location, base_uri: @base_uri)
        raise Error.new("#{path}.location could not be resolved") unless uri
        if uri.starts_with?(/sarif:/i)
          external = inline_at(uri, path)
        else
          external_file = true
          external = @loaded[uri] ||= @loader.call(uri)
        end
      elsif guid = ref.guid
        entries = @inline_by_guid[guid.downcase]?
        unless entries && entries.size == 1
          raise Error.new("#{path}.guid must identify exactly one inline external properties object: '#{guid}'")
        end
        external = entries.first
      else
        raise Error.new("#{path} must have a location or guid")
      end

      if (external_file || external.version) && external.version != SARIF_VERSION
        raise Error.new("#{path} points to external properties that require version #{SARIF_VERSION}")
      end
      if (guid = ref.guid) && external.guid.try(&.downcase) != guid.downcase
        raise Error.new("#{path}.guid does not match the external properties GUID")
      end
      if (guid = external.run_guid) && run.automation_details.try(&.guid).try(&.downcase) != guid.downcase
        raise Error.new("#{path} points to external properties for a different runGuid")
      end
      external
    end

    private def inline_at(uri : String, path : String) : ExternalProperties
      pointer = uri.byte_slice("sarif:".bytesize)
      if !pointer.includes?('?') && !pointer.includes?('#') &&
         (match = INLINE_POINTER.match(URI.decode(pointer))) && (index = match[1].to_i?)
        if entry = @inline.try(&.[index]?)
          return entry
        end
      end
      raise Error.new("#{path}.location does not point to inline external properties: '#{uri}'")
    end
  end
end
