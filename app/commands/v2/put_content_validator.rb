module Commands
  module V2
    class PutContentValidator
      FORMATS_WITHOUT_BASE_PATH_VALIDATION = %w[
        contact
        content_block
        external_content
        government
        redirect
        role
        role_appointment
        world_location
      ].freeze

      def initialize(payload, put_content)
        @payload = payload
        @put_content = put_content
      end

      def validate
        validate_schema
        validate_publishing_app
        validate_base_path
      end

    private

      attr_reader :payload, :put_content

      def validate_schema
        return if schema_validator.valid?

        message = "The payload did not conform to the schema"
        raise CommandError.new(
          code: 422,
          error_code: :schema_validation_failed,
          message:,
          error_details: schema_validator.errors,
        )
      end

      def validate_publishing_app
        return if payload[:publishing_app].present?

        code = 422
        message = "publishing_app is required"
        raise CommandError.new(
          code:,
          error_code: :publishing_app_missing,
          message:,
          error_details: {
            error: {
              code:,
              message:,
              fields: { publishing_app: ["is required"] },
            },
          },
        )
      end

      def validate_base_path
        return if FORMATS_WITHOUT_BASE_PATH_VALIDATION.include?(payload[:schema_name])

        base_path_validator = GdsApi::Validators::BasePathValidator.new(payload[:base_path])
        return if base_path_validator.valid?

        code = 422
        message = "base_path did not conform to standard"
        raise CommandError.new(
          code:,
          error_code: :base_path_invalid,
          message:,
          error_details: {
            error: {
              code:,
              message:,
              fields: base_path_validator.errors,
            },
          },
        )
      end

      def schema_validator
        @schema_validator ||= SchemaValidator.new(payload: payload.except(:content_id))
      end
    end
  end
end
