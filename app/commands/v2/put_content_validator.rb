module Commands
  module V2
    class PutContentValidator
      def initialize(payload, put_content)
        @payload = payload
        @put_content = put_content
      end

      def validate
        validate_schema

        if payload[:publishing_app].blank?
          put_content.send(:raise_command_error, 422, "publishing_app is required", fields: {
            publishing_app: ["is required"]
          })
        end
      end

    private

      attr_reader :payload, :put_content

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
