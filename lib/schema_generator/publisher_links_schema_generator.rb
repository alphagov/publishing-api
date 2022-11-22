module SchemaGenerator
  class PublisherLinksSchemaGenerator
    def initialize(format, global_definitions)
      @format = format
      @global_definitions = global_definitions
    end

    def generate
      {
        "$schema" => "http://json-schema.org/draft-04/schema#",
        "type" => "object",
        "additionalProperties" => false,
        # Note that we don't allow `required` links because this would prevent
        # publishing-api to validate partial payload for PATCH requests.
        "properties" => properties,
        "definitions" => definitions,
      }
    end

  private

    attr_reader :format, :global_definitions

    def properties
      {
        "links" => links,
        "previous_version" => { "type" => "string" },
        "bulk_publishing" => { "type" => "boolean" },
      }
    end

    def definitions
      all_definitions = global_definitions.merge(format.definitions)
      DefinitionsResolver.new(properties, all_definitions).call
    end

    def links
      {
        "type" => "object",
        "additionalProperties" => false,
        "properties" => format.content_links.guid_properties,
      }
    end
  end
end
