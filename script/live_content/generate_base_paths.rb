# bundle exec rails runner script/live_content/generate_base_paths.rb

schema_names = Dir
  .children(Rails.root.join("app/graphql/queries"))
  .map { _1.split(".").first }

base_paths = schema_names.flat_map { |schema_name|
  document_types = GovukSchemas::Schema
    .find(frontend_schema: schema_name)
    .dig("properties", "document_type", "enum")

  document_types.map do |document_type|
    Edition
      .live
      .joins(:document)
      .where(schema_name:, document_type:, document: { locale: "en" })
      .where.not(state: "unpublished")
      .where.not(base_path: nil)
      .pick(:base_path)
  end
}.compact

puts base_paths
