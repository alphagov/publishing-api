require "yaml"

module SchemaGenerator
  class Format
    attr_reader :schema_name

    def initialize(schema_name, format_data)
      @schema_name = schema_name
      @format_data = format_data
    end

    def document_type
      @document_type ||= DocumentType.new(format_data["document_type"])
    end

    def base_path
      @base_path ||= OptionalProperty.new(
        property: "base_path",
        status: format_data["base_path"] || "required",
        required_definition: "absolute_path",
        optional_definition: "absolute_path_optional",
        forbidden_definition: "null",
      )
    end

    def description
      @description ||= OptionalProperty.new(
        property: "description",
        status: format_data["description"] || "optional",
        required_definition: "description",
        optional_definition: "description_optional",
        forbidden_definition: "null",
      )
    end

    def details
      @details ||= OptionalProperty.new(
        property: "details",
        status: format_data["details"] || "required",
        required_definition: "details",
        optional_definition: "details",
        forbidden_definition: "empty_object",
      )
    end

    def redirects
      @redirects ||= OptionalProperty.new(
        property: "redirects",
        status: format_data["redirects"] || "required",
        required_definition: "redirects",
        optional_definition: "redirects_optional",
        forbidden_definition: "empty_array",
      )
    end

    def rendering_app
      @rendering_app ||= OptionalProperty.new(
        property: "base_path",
        status: format_data["rendering_app"] || "required",
        required_definition: "rendering_app",
        optional_definition: "rendering_app_optional",
        forbidden_definition: "null",
      )
    end

    def routes
      @routes ||= OptionalProperty.new(
        property: "routes",
        status: format_data["routes"] || "required",
        required_definition: "routes",
        optional_definition: "routes_optional",
        forbidden_definition: "empty_array",
      )
    end

    def title
      @title ||= OptionalProperty.new(
        property: "title",
        status: format_data["title"] || "required",
        required_definition: "title",
        optional_definition: "title_optional",
        forbidden_definition: "null",
      )
    end

    def content_id(frontend: false)
      frontend_status = format_data["frontend_content_id"] || "required"
      OptionalProperty.new(
        property: "content_id",
        status: frontend ? frontend_status : "required",
        required_definition: "guid",
        optional_definition: "guid_optional",
        forbidden_definition: "null",
      )
    end

    def generate_publisher?
      generate_publisher = format_data.dig("generate", "publisher")
      generate_publisher.nil? ? true : generate_publisher
    end

    def generate_notification?
      generate_notification = format_data.dig("generate", "notification")
      generate_notification.nil? ? true : generate_notification
    end

    def generate_frontend?
      generate = format_data.dig("generate", "frontend")
      generate = true if generate.nil?
      generate && !base_path.forbidden?
    end

    def definitions
      format_data["definitions"] || {}
    end

    def edition_links
      @edition_links ||= create_edition_links
    end

    def content_links
      @content_links ||= create_content_links
    end

    def schema_name_definition
      {
        "enum" => [schema_name],
        "type" => "string",
      }
    end

    def publisher_required
      %w[base_path description details redirects rendering_app routes title]
        .select { |property| public_send(property.to_sym).required? }
    end

  private

    attr_reader :format_data

    def create_edition_links
      links_data = format_data.fetch("edition_links", {})
      Links.new(links_data)
    end

    def create_content_links
      links_data = format_data.fetch("links", {})
      links = Links.new(links_data)
      if links.required_links.any?
        raise InvalidFormat, "Can only require edition links"
      end

      links
    end

    class DocumentType
      attr_reader :document_types

      def initialize(document_types)
        @document_types = document_types
      end

      def definition
        if document_types.blank?
          return build_definition(allowed_document_types)
        end

        specified_document_types = Array(document_types)
        disallowed = specified_document_types - allowed_document_types
        if disallowed.any?
          raise InvalidFormat, "Encountered document types which are not allowed in `content_schemas/allowed_document_types.yml`: #{disallowed.join(', ')}"
        end

        build_definition(specified_document_types)
      end

    private

      def build_definition(document_types)
        { "enum" => document_types, "type" => "string" }
      end

      def allowed_document_types
        @allowed_document_types ||= YAML.load_file(allowed_document_types_path)
      end

      def allowed_document_types_path
        File.expand_path("./content_schemas/allowed_document_types.yml")
      end
    end

    class OptionalProperty
      VALID_STATUSES = %w[required optional forbidden].freeze

      def initialize(
        property:,
        status:,
        required_definition:,
        optional_definition:,
        forbidden_definition:
      )
        @property = property
        @status = status
        @required_definition = required_definition
        @optional_definition = optional_definition
        @forbidden_definition = forbidden_definition

        unless VALID_STATUSES.include?(status)
          raise InvalidFormat, "Invalid value for #{property}: #{status}. Expected #{VALID_STATUSES.join(', ')}"
        end
      end

      def optional?
        !required? && !forbidden?
      end

      def required?
        status == "required"
      end

      def forbidden?
        status == "forbidden"
      end

      def definition
        determined = determined_definition
        case determined
        when "null"
          { "type" => "null" }
        when "empty_array"
          {
            "type" => "array",
            "items" => {},
            "additionalItems" => false,
          }
        when "empty_object"
          {
            "type" => "object",
            "properties" => {},
            "additionalProperties" => false,
          }
        else
          { "$ref" => "#/definitions/#{determined}" }
        end
      end

    private

      attr_reader :property, :status, :required_definition,
                  :optional_definition, :forbidden_definition

      def determined_definition
        return forbidden_definition if forbidden?
        return required_definition if required?

        optional_definition
      end
    end

    class Links
      ALLOWED_KEYS = %w[description required minItems maxItems].freeze
      LINKS_WITHOUT_BASE_PATHS = %w[
        contact
        facets
        home_page_offices
        main_office
        office_staff
        ordered_also_attends_cabinet
        ordered_assistant_whips
        ordered_baronesses_and_lords_in_waiting_whips
        ordered_board_members
        ordered_cabinet_ministers
        ordered_chief_professional_officers
        ordered_contacts
        ordered_foi_contacts
        ordered_house_lords_whips
        ordered_house_of_commons_whips
        ordered_junior_lords_of_the_treasury_whips
        ordered_military_personnel
        ordered_ministerial_departments
        ordered_ministers
        ordered_roles
        ordered_special_representatives
        ordered_traffic_commissioners
        primary_role_person
        secondary_role_person
        world_locations
        worldwide_organisation
      ].freeze

      attr_reader :links

      def initialize(links_data)
        @links = normalise_links(links_data)
      end

      def guid_properties
        links.each_with_object({}) do |(k, v), hash|
          link = v.merge("$ref" => "#/definitions/guid_list")
            .delete_if { |key| %w[required].include?(key) }
          hash[k] = link
        end
      end

      def required_links
        links.each_with_object([]) do |(k, v), memo|
          memo << k if v["required"]
        end
      end

      def frontend_properties
        links.each_with_object({}) do |(k, v), hash|
          # It's possible for all link types to contain items without base_paths
          # however apps aren't coded for this so fail on this, therefore
          # this legacy fix is included.
          # @FIXME remove need for this check
          definition = LINKS_WITHOUT_BASE_PATHS.include?(k) ? "frontend_links" : "frontend_links_with_base_path"
          link = v.merge("$ref" => "#/definitions/#{definition}")
            .delete_if { |field| %w[required minItems].include?(field) }
          hash[k] = link
        end
      end

    private

      def normalise_links(links_data)
        links_data.each_with_object({}) do |(k, v), hash|
          next unless v

          if v.is_a?(Hash)
            extra_keys = v.keys - ALLOWED_KEYS
            if extra_keys.any?
              raise InvalidFormat, "Unexpected keys #{extra_keys.join(', ')} for link - only #{ALLOWED_KEYS.join(', ')} are allowed"
            end

            definition = v
          else
            definition = {}
            definition["description"] = v unless v.empty?
          end

          hash[k] = definition
        end
      end
    end
  end

  class InvalidFormat < RuntimeError; end
end
