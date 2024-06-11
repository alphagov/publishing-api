class SchemaService
  def self.all_schemas
    format_regex = Regexp.new(".+\/formats\/([a-z_]+)\/.+")
    GovukSchemas::Schema.all(schema_type: "publisher")
                        .select { |k| k.ends_with?("schema.json") }
                        .transform_keys { |k| format_regex.match(k)[1] }
  end
end
