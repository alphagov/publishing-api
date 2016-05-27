require 'json-schema'

class SchemaValidator
  def initialize(payload, type:, schema: nil)
    @payload = payload
    @type = type
    @schema = schema
  end

  def validate
    validate_schema
  end

private

  attr_reader :payload, :type

  def validate_schema
    JSON::Validator.validate!(schema, payload)
  rescue JSON::Schema::ValidationError => error
    Airbrake.notify_or_ignore(error, parameters: {
      explanation: "schema validation error"
    })
    false
  end

  def schema
    @schema || File.read("govuk-content-schemas/formats/#{format}/publisher_v2/#{type}.json")
  rescue Errno::ENOENT => error
    Airbrake.notify_or_ignore(error, parameters: {
      explanation: "format #{format} or type #{type} is not known"
    })
    return {}
  end

  def format
    payload[:format]
  end
end
