require "json-schema"
require "govuk_schemas"

class SchemaValidator
  attr_reader :errors

  def initialize(payload:, schema: nil, schema_name: nil, schema_type: :publisher)
    @payload = payload
    @schema = schema
    @schema_name = schema_name
    @schema_type = schema_type
    @errors = []
  end

  def valid?
    @errors += JSON::Validator.fully_validate(
      schema,
      payload,
      errors_as_objects: true,
    )
    errors.empty?
  end

private

  attr_reader :payload, :schema_type

  def schema
    @schema || find_schema
  rescue NoSchemaNameError
    errors << no_schema_name_message
    {}
  rescue Errno::ENOENT
    errors << missing_schema_message
    {}
  end

  def find_schema
    GovukSchemas::Schema.find(find_type)
  end

  def find_type
    raise NoSchemaNameError, "No schema name provided" if schema_name.blank?

    { schema_type_key => schema_name }
  end

  def schema_type_key
    "#{schema_type}_schema".to_sym
  end

  def schema_name
    @schema_name || payload[:schema_name]
  end

  def missing_schema_message
    "Unable to find schema for schema_name #{schema_name}"
  end

  def no_schema_name_message
    "Schema could not be validated as the schema_name was not provided"
  end

  class NoSchemaNameError < StandardError
  end
end
