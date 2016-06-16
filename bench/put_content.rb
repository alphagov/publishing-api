# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)
require 'benchmark'
require 'securerandom'

require 'faker'
require 'stackprof'

content_id = SecureRandom.uuid
title = Faker::Company.catch_phrase

content_items = 100.times.map do
  {
    content_id: content_id,
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
      body: "<p>#{Faker::Lorem.paragraphs(10)}</p>"
    },
    phase: 'live',
    need_ids: []
  }
end

$queries = 0
ActiveSupport::Notifications.subscribe "sql.active_record" do |name, started, finished, unique_id, data|
  $queries += 1
end

StackProf.run(mode: :wall, out: "tmp/put_content_wall.dump") do
  puts Benchmark.measure {
    content_items.each do |item|
      Commands::V2::PutContent.call(item)
      print "."
    end
    puts ""
  }
end

puts "#{$queries} SQL queries"

ContentItem.where("(routes->>0)::json->>'path' LIKE '/performance-testing/%'").each do |ci|
  LinkSet.where(content_id: ci.content_id).destroy_all
  Location.where(content_item: ci).delete_all
  State.where(content_item: ci).delete_all
  Translation.where(content_item: ci).delete_all
  UserFacingVersion.where(content_item: ci).delete_all
  LockVersion.where(target: ci).delete_all
  ci.destroy
end
