module Commands
  module V2
    class PutContentValidator
      def initialize(payload, put_content)
        @payload = payload
        @put_content = put_content
      end

      def validate
        raise_if_links_are_provided
        validate_schema

        if payload[:publishing_app].blank?
          put_content.send(:raise_command_error, 422, "publishing_app is required", fields: {
            publishing_app: ["is required"]
          })
        end
      end

    private

      attr_reader :payload, :put_content

      def raise_if_links_are_provided
        return unless payload.has_key?(:links)
        message = "The 'links' parameter should not be provided to this endpoint."

        raise CommandError.new(
          code: 400,
          message: message,
          error_details: {
            error: {
              code: 400,
              message: message,
              fields: {
                links: ["is not a valid parameter"],
              }
            }
          }
        )
      end

      def validate_schema
        return if schema_validator.valid?
        message = "The payload did not conform to the schema"
        raise CommandError.new(
          code: 422,
          message: message,
          error_details: schema_validator.errors,
        )
      end

      def schema_validator
        @schema_validator ||= SchemaValidator.new(payload: payload.except(:content_id))
      end
    end
  end
end
