module SchemaGenerator
  class NotificationSchemaGenerator
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
      if unpublishing_format?
        default_required_properties.sort
      else
        (default_required_properties + publishing_required_properties).sort
      end
    end

    def unpublishing_format?
      %w[gone redirect vanish substitute].include?(format.schema_name)
    end

    def properties
      default_properties.merge(derived_properties)
    end

    def default_properties
      Jsonnet.load("content_schemas/formats/shared/default_properties/notification.jsonnet")
    end

    def derived_properties
      {
        "base_path" => format.base_path.definition,
        "content_id" => format.content_id(frontend: false).definition,
        "document_type" => format.document_type.definition,
        "description" => format.description.definition,
        "details" => format.details.definition,
        "expanded_links" => ExpandedLinks.new(format).generate,
        "links" => unexpanded_links,
        "redirects" => format.redirects.definition,
        "rendering_app" => format.rendering_app.definition,
        "routes" => format.routes.definition,
        "schema_name" => format.schema_name_definition,
        "title" => format.title.definition,
      }
    end

    def default_required_properties
      %w[
        base_path
        content_id
        locale
        document_type
        govuk_request_id
        payload_version
        schema_name
      ]
    end

    def publishing_required_properties
      %w[
        analytics_identifier
        description
        details
        email_document_supertype
        expanded_links
        first_published_at
        government_document_supertype
        links
        phase
        public_updated_at
        publishing_app
        redirects
        rendering_app
        routes
        title
        update_type
      ]
    end

    def definitions
      all_definitions = global_definitions.merge(format.definitions)
      ApplyChangeHistoryDefinitions.call(all_definitions)
      DefinitionsResolver.new(properties, all_definitions).call
    end

    def unexpanded_links
      content_links = format.content_links.guid_properties
      edition_links = format.edition_links.guid_properties
      {
        "type" => "object",
        "additionalProperties" => false,
        "properties" => content_links.merge(edition_links),
      }
    end
  end
end
