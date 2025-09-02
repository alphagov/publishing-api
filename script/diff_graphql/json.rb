#!/usr/bin/env ruby

require "fileutils"
require "json"
require "net/http"
require "uri"

# Using a list of base paths, render each page with Content Store and Publishing
# API's GraphQL endpoint as the data source and diff the results.

OUTPUT_DIR = "tmp/diff_graphql/content_items"

FileUtils.mkdir_p(OUTPUT_DIR)

def usage
  abort("Usage:\n\t#{$PROGRAM_NAME} a_base_path")
end

base_path = ARGV.fetch(0) { usage }

publishing_api_uri = URI("http://publishing-api.dev.gov.uk/graphql/content#{base_path}")
content_store_uri = URI("http://content-store.dev.gov.uk/content#{base_path}")

publishing_api_json = JSON.pretty_generate(JSON.parse(Net::HTTP.get(publishing_api_uri)))
content_store_json = JSON.pretty_generate(JSON.parse(Net::HTTP.get(content_store_uri)))

publishing_api_file_path = File.join(OUTPUT_DIR, "publishing_api_response.json")
content_store_file_path = File.join(OUTPUT_DIR, "content_store_response.json")

File.write(publishing_api_file_path, publishing_api_json)
File.write(content_store_file_path, content_store_json)

puts(`diff #{publishing_api_file_path} #{content_store_file_path}`)
