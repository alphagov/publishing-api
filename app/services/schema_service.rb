class SchemaService
  def self.all_schemas
    format_regex = Regexp.new(".+\/formats\/([a-z_]+)\/.+")
    GovukSchemas::Schema.all(schema_type: "publisher")
                        .select { |k| k.ends_with?("schema.json") }
                        .transform_keys { |k| format_regex.match(k)[1] }
  end

  def self.find_schema_by_name(name)
    GovukSchemas::Schema.find(publisher_schema: name)
  rescue Errno::ENOENT
    message = "Could not find publisher schema with name: #{name}"
    raise CommandError.new(code: 404, message:)
  end
end
