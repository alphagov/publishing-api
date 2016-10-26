require 'json-schema'

class SchemaValidator
  attr_reader :errors

  def initialize(type:, schema_name: nil, schema: nil)
    @errors = []
    @type = type
    @schema = schema
    @schema_name = schema_name
  end

  def validate(payload)
    @payload = payload

    return true if schema_name_exception?

    @errors += JSON::Validator.fully_validate(
      schema,
      payload,
      errors_as_objects: true,
    )
    errors.empty?
  end

private

  attr_reader :payload, :type

  def schema
    @schema || find_schema
  rescue Errno::ENOENT => error
    if Rails.env.development?
      errors << missing_schema_message
      errors << dev_help
    end
    Airbrake.notify(error, parameters: {
      explanation: missing_schema_message,
      schema_path: ENV["GOVUK_CONTENT_SCHEMAS_PATH"],
    })
    {}
  end

  def find_schema
    GovukSchemas::Schema.find(schema_name, schema_type: type)
  end

  def schema_name
    @schema_name || payload[:schema_name] || payload[:format]
  end

  def schema_name_exception?
    schema_name.to_s.match(/placeholder_/)
  end

  def missing_schema_message
    "Unable to find schema for schema_name #{schema_name} and type #{type}"
  end

  def dev_help
    "Ensure GOVUK_CONTENT_SCHEMAS_PATH env variable is set and points to the dist directory of govuk-content-schemas"
  end
end
