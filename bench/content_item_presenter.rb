# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)
require 'stackprof'
require 'benchmark'

$queries = 0
ActiveSupport::Notifications.subscribe "sql.active_record" do |name, started, finished, unique_id, data|
  $queries += 1
end

def present(number_of_items)
  scope = Edition.limit(number_of_items).order("id DESC")
  $queries = 0

  puts "Presenting #{number_of_items} content items"
  StackProf.run(mode: :wall, out: "tmp/content_item_presenter_#{number_of_items}_wall.dump") do
    puts Benchmark.measure { Presenters::Queries::ContentItemPresenter.present_many(scope).to_a }
  end
  puts "  Queries: #{$queries}"
end

6.upto(10) { |i| present(2 ** i) }
