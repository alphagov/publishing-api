# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)
require "benchmark"
require "securerandom"

require "faker"
require "stackprof"

abort "Refusing to run outside of development" unless Rails.env.development?

$queries = 0
ActiveSupport::Notifications.subscribe "sql.active_record" do |_name, _started, _finished, _unique_id, _data|
  $queries += 1
end

new_item = (ARGV.first == "--new-item")
redraft = (ARGV.first == "--redraft")

content_id = SecureRandom.uuid
title = Faker::Company.catch_phrase

editions = 100.times.map do
  title = Faker::Company.catch_phrase if new_item
  content_id = SecureRandom.uuid if new_item
  {
    content_id: content_id,
    schema_name: "placeholder",
    document_type: "placeholder",
    title: title,
    base_path: "/performance-testing/#{title.parameterize}",
    description: Faker::Lorem.paragraph,
    public_updated_at: Time.now.iso8601,
    locale: "en",
    routes: [
      { path: "/performance-testing/#{title.parameterize}", type: "exact" },
    ],
    redirects: [],
    publishing_app: "performance-testing",
    rendering_app: "performance-testing",
    details: {},
    phase: "live",
  }
end

begin
  if redraft
    puts "Creating published items..."
    editions.each do |item|
      Commands::V2::PutContent.call(item)
      Commands::V2::Publish.call(content_id: item[:content_id], update_type: "major")
    end
    $queries = 0

    puts "Publishing..."
    StackProf.run(mode: :wall, out: "tmp/put_content_wall.dump") do
      puts Benchmark.measure {
        editions.each do |item|
          Commands::V2::PutContent.call(item.merge(title: Faker::Company.catch_phrase))
          print "."
        end
        puts ""
      }
    end
  else
    StackProf.run(mode: :wall, out: "tmp/put_content_wall.dump") do
      puts Benchmark.measure {
        editions.each do |item|
          Commands::V2::PutContent.call(item)
          print "."
        end
        puts ""
      }
    end
  end

  puts "#{$queries} SQL queries"
ensure
  scope = Edition.includes(:document).where(publishing_app: "performance-testing").joins(:document)
  LinkSet.includes(:links).where(content_id: scope.pluck(:content_id)).destroy_all
  scope.delete_all
end
