require "schema_generator/generator"
require "jsonnet"

desc "Regenerate schemas"
task regenerate_schemas: :environment do
  print "Generating schemas: "
  FileUtils.rm_rf("content_schemas/dist/formats")

  # Ignore files prefixed with an underscore
  Dir.glob("content_schemas/formats/{[!_]*}.jsonnet").each do |schema_filename|
    schema_name = File.basename(schema_filename, ".*")
    SchemaGenerator::Generator.generate(schema_name, Jsonnet.load(schema_filename))
    print "."
  end

  puts "✔︎"
end
