# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)
require 'benchmark'
require 'securerandom'

require 'faker'

ContentItem.where("(routes->>0)::json->>'path' LIKE '/performance-testing/%'").each do |ci|
  State.where(content_item: ci).destroy_all
  Location.where(content_item: ci).destroy_all
  Translation.where(content_item: ci).destroy_all
  UserFacingVersion.where(content_item: ci).destroy_all
  LinkSet.where(content_id: ci.content_id).destroy_all
  ci.destroy
end

content_items = 100.times.map do
  title = Faker::Company.catch_phrase
  {
    content_id: SecureRandom.uuid,
    format: "placeholder",
    schema_name: "placeholder",
    document_type: "placeholder",
    title: title,
    base_path: "/performance-testing/#{title.parameterize}",
    description: Faker::Lorem.paragraph,
    public_updated_at: Time.now.iso8601,
    locale: "en",
    routes: [
      {path: "/performance-testing/#{title.parameterize}", type: "exact"}
    ],
    redirects: [],
    publishing_app: "test",
    rendering_app: "test",
    details: {
      body: "<p>#{Faker::Lorem.paragraph}</p>"
    }
  }
end

$queries = 0
ActiveSupport::Notifications.subscribe "sql.active_record" do |name, started, finished, unique_id, data|
  $queries += 1
end

puts Benchmark.measure {
  content_items.each do |item|
    Commands::V2::PutContent.call(item)
    print "."
  end
  puts ""
}

puts "#{$queries} SQL queries"
