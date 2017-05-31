module Commands
  module V2
    class PutContentValidator
      def initialize(payload, put_content)
        @payload = payload
        @put_content = put_content
      end

      def validate
        validate_schema
        validate_publishing_app
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

      def validate_publishing_app
        return unless payload[:publishing_app].blank?
        code = 422
        message = "publishing_app is required"
        raise CommandError.new(
          code: code,
          message: message,
          error_details: {
            error: {
              code: code,
              message: message,
              fields: { publishing_app: ["is required"] }
            }
          }
        )
      end

      def schema_validator
        @schema_validator ||= SchemaValidator.new(payload: payload.except(:content_id))
      end
    end
  end
end
