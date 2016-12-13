require 'json-schema'
require 'govuk_schemas'

class SchemaValidator
  attr_reader :errors

  def initialize(payload:, links: false, schema: nil, schema_name: nil)
    @payload = payload
    @links = links
    @schema = schema
    @schema_name = schema_name
    @errors = []
  end

  def valid?
    return true if schema_name_exception?
    @errors += JSON::Validator.fully_validate(
      schema,
      payload,
      errors_as_objects: true,
    )
    errors.empty?
  end

private

  attr_reader :payload, :links

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
    @schema || GovukSchemas::Schema.find(find_type)
  end

  def find_type
    if links?
      { links_schema: schema_name }
    else
      { publisher_schema: schema_name }
    end
  end

  def links?
    links
  end

  def schema_name
    @schema_name || payload[:schema_name]
  end

  def schema_name_exception?
    schema_name.to_s.match(/placeholder_/)
  end

  def missing_schema_message
    "Unable to find schema for schema_name #{schema_name}"
  end

  def dev_help
    "Ensure GOVUK_CONTENT_SCHEMAS_PATH env variable is set and points to the root directory of govuk-content-schemas"
  end
end
