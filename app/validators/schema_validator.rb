require 'json-schema'

class SchemaValidator
  def initialize(payload, type:, schema_name: nil, schema: nil)
    @payload = payload
    @type = type
    @schema = schema
    @schema_name = schema_name
  end

  def validate
    return true if schema_name_exception?
    validate_schema
  end

private

  attr_reader :payload, :type

  def validate_schema
    errors = JSON::Validator.fully_validate(
      schema,
      payload,
      errors_as_objects: true,
    )

    return true if errors.empty?

    Airbrake.notify_or_ignore(
      {
        error_class: "SchemaValidationError",
        error_message: "Error validating payload against schema"
      },
      parameters: {
        errors: errors,
        message_data: payload
      }
    )
    false
  end

  def schema
    @schema || JSON.load(File.read("govuk-content-schemas/formats/#{schema_name}/publisher_v2/#{type}.json"))
  rescue Errno::ENOENT => error
    Airbrake.notify_or_ignore(error, parameters: {
      explanation: "#{payload} is missing schema_name #{schema_name} or type #{type}"
    })
    @schema = {}
  end

  def schema_name
    @schema_name || payload[:schema_name] || payload[:format]
  end

  def schema_name_exception?
    schema_name.to_s.match(/placeholder_/)
  end
end
