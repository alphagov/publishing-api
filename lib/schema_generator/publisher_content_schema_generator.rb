module SchemaGenerator
  class PublisherContentSchemaGenerator
    def initialize(format, global_definitions)
      @format = format
      @global_definitions = global_definitions
    end

    def generate
      {
        "$schema" => "http://json-schema.org/draft-04/schema#",
        "type" => "object",
        "additionalProperties" => false,
        "required" => required,
        "properties" => properties,
        "definitions" => definitions,
      }
    end

  private

    attr_reader :format, :global_definitions

    def required
      fields = %w[
        document_type
        publishing_app
        schema_name
      ] + format.publisher_required
      fields.sort
    end

    def properties
      default_properties.merge(derived_properties)
    end

    def default_properties
      Jsonnet.load("formats/shared/default_properties/publisher.jsonnet")
    end

    def derived_properties
      {
        "base_path" => format.base_path.definition,
        "document_type" => format.document_type.definition,
        "description" => format.description.definition,
        "details" => format.details.definition,
        "links" => links,
        "redirects" => format.redirects.definition,
        "rendering_app" => format.rendering_app.definition,
        "routes" => format.routes.definition,
        "schema_name" => format.schema_name_definition,
        "title" => format.title.definition,
      }
    end

    def definitions
      all_definitions = global_definitions.merge(format.definitions)
      DefinitionsResolver.new(properties, all_definitions).call
    end

    def links
      links = {
        "type" => "object",
        "additionalProperties" => false,
        "properties" => format.edition_links.guid_properties,
      }
      required_links = format.edition_links.required_links
      links["required"] = required_links if required_links.any?
      links
    end
  end
end
