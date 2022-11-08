require "jsonnet"
require "schema_generator/schema"
require "schema_generator/publisher_content_schema_generator"
require "schema_generator/publisher_links_schema_generator"
require "schema_generator/frontend_schema_generator"
require "schema_generator/notification_schema_generator"
require "schema_generator/format"
require "schema_generator/definitions_resolver"
require "schema_generator/expanded_links"
require "schema_generator/apply_change_history_definitions"

module SchemaGenerator
  module Generator
    # @param schema_name [String] like `generic` or `specialist_document`
    # @param data [Hash] the data from the format definition
    def self.generate(schema_name, data)
      format = Format.new(schema_name, data)
      global_definitions = load_global_definitions

      if format.generate_publisher?
        publisher_content_schema = PublisherContentSchemaGenerator.new(
          format, global_definitions
        ).generate
        Schema.write("content_schemas/dist/formats/#{schema_name}/publisher_v2/schema.json", publisher_content_schema)

        publisher_links_schema = PublisherLinksSchemaGenerator.new(
          format, global_definitions
        ).generate
        Schema.write("content_schemas/dist/formats/#{schema_name}/publisher_v2/links.json", publisher_links_schema)
      end

      if format.generate_notification?
        notification_schema = NotificationSchemaGenerator.new(
          format, global_definitions
        ).generate
        Schema.write("content_schemas/dist/formats/#{schema_name}/notification/schema.json", notification_schema)
      end

      if format.generate_frontend?
        frontend_schema = FrontendSchemaGenerator.new(
          format, global_definitions
        ).generate
        Schema.write("content_schemas/dist/formats/#{schema_name}/frontend/schema.json", frontend_schema)
      end
    rescue InvalidFormat => e
      raise "Could not generate #{schema_name} as the format file is invalid. #{e.message}"
    rescue DefinitionsResolver::UnresolvedDefinition => e
      raise "Could not generate #{schema_name} as a definition for `#{e.definition}` was not found"
    end

    def self.load_global_definitions
      definitions_path = "content_schemas/formats/shared/definitions/**/{[!_]*}.jsonnet"
      Dir.glob(definitions_path).inject({}) do |memo, file_path|
        memo.merge(Jsonnet.load(file_path))
      end
    end
  end
end
