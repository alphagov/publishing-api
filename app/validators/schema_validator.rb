require 'json-schema'

class SchemaValidator
  def initialize(type:, schema_name: nil, schema: nil)
    @type = type
    @schema = schema
    @schema_name = schema_name
  end

  def validate(payload)
    @payload = payload

    return true if schema_name_exception?

    errors = JSON::Validator.fully_validate(
      schema,
      payload,
      errors_as_objects: true,
    )

    return true if errors.empty?

    errors = errors.map { |e| present_error e }

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

private

  attr_reader :payload, :type

  def present_error(error_hash)
    # The schema key just contains an addressable, which is not informative as
    # the schema in use should be clear from the error class and message
    error_hash = error_hash.reject { |k,v| k == :schema }

    if error_hash.has_key? :errors
      error_hash[:errors] = Hash[
        error_hash[:errors].map {|k,errors| [k,errors.map { |e| present_error e }]}
      ]
    end

    error_hash
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
