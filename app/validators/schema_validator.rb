require 'json-schema'

class SchemaValidator
  attr_reader :errors

  def initialize(type:, schema_name: nil, schema: nil)
    @type = type
    @schema = schema
    @schema_name = schema_name
  end

  def validate(payload)
    @payload = payload

    return true if schema_name_exception?

    @errors = JSON::Validator.fully_validate(
      schema,
      payload,
      errors_as_objects: true,
    )
    errors.empty?
  end

private

  attr_reader :payload, :type

  def schema
    @schema || JSON.load(File.read(schema_filepath))
  rescue Errno::ENOENT => error
    msg = "Unable to find schema for schema_name #{schema_name} and type #{type}"
    Airbrake.notify_or_ignore(error, parameters: { explanation: msg })
    {}
  end

  def schema_filepath
    File.join(
      "govuk-content-schemas",
      "formats",
      schema_name,
      "publisher_v2",
      "#{type}.json"
    )
  end

  def schema_name
    @schema_name || payload[:schema_name] || payload[:format]
  end

  def schema_name_exception?
    schema_name.to_s.match(/placeholder_/)
  end
end
