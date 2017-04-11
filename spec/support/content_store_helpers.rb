module ContentStoreHelpers
  def schemas_of_type(schema_type)
    GovukSchemas::Schema.all
      .select { |path, _| path.ends_with? "#{schema_type}.json" }
  end
end

RSpec.configure do |c|
  c.extend ContentStoreHelpers
end
