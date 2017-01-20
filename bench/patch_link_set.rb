# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)
require 'benchmark'
require 'securerandom'

require 'faker'
require 'stackprof'

abort "Refusing to run outside of development" unless Rails.env.development?

$queries = 0
ActiveSupport::Notifications.subscribe "sql.active_record" do |name, started, finished, unique_id, data|
  $queries += 1
end

content_items = 100.times.map do
  title = Faker::Company.catch_phrase
  {
    content_id: SecureRandom.uuid,
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
    publishing_app: "performance-testing",
    rendering_app: "performance-testing",
    details: {
      body: "<p>#{Faker::Lorem.paragraphs(10)}</p>"
    },
    phase: 'live',
    need_ids: []
  }
end

begin
  puts "Publishing content items..."
  content_items.each do |item|
    Commands::V2::PutContent.call(item)
    Commands::V2::Publish.call(content_id: item[:content_id], update_type: 'major')
  end

  $queries = 0

  puts "Patching links..."

  content_ids = content_items.map { |ci| ci[:content_id] }
  payloads = content_items.map do |ci|
    links = content_ids.sample(10).reject { |id| id == ci[:content_id] }
    {content_id: ci[:content_id], links: {foos: links}}
  end

  StackProf.run(mode: :wall, out: "tmp/patch_link_set_wall.dump") do
    puts Benchmark.measure {
      payloads.each do |payload|
        Commands::V2::PatchLinkSet.call(payload)
        print "."
      end
      puts
    }
  end

  puts "#{$queries} SQL queries"

ensure
  scope = Edition.where(publishing_app: 'performance-testing')
  LinkSet.includes(:links).where(content_id: scope.pluck(:content_id)).destroy_all
  Location.where(content_item: scope).delete_all
  State.where(content_item: scope).delete_all
  Translation.where(content_item: scope).delete_all
  UserFacingVersion.where(edition: scope).delete_all
  LockVersion.where(target: scope).delete_all
  PathReservation.where(publishing_app: 'performance-testing').delete_all
  scope.delete_all
end
