require "schema_generator/generator"
require "jsonnet"

desc "Build individual schema"
task :build_schema, [:schema] => :environment do |_, args|
  raise "Missing parameter: schema" unless args.schema

  schema_name = args.schema

  print "Generating schema: #{schema_name}"

  FileUtils.rm_rf("content_schemas/dist/formats/#{schema_name}")

  schema_filename = "content_schemas/formats/#{schema_name}.jsonnet"
  SchemaGenerator::Generator.generate(schema_name, Jsonnet.load(schema_filename))
  puts " ✔︎"
end
