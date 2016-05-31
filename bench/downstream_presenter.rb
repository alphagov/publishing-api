# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)
require 'benchmark'

large_reverse_content_item = Queries::GetLatest.(ContentItemFilter.new(
  scope: ContentItem.where(content_id: '6667cce2-e809-4e21-ae09-cb0bdc1ddda3')
).filter(state: 'published')).first

puts "Reverse dependencies"
puts Benchmark.measure {
  10.times do |i|
    Rails.logger.debug "Iteration #{i}"
    Rails.logger.debug "-----------"
    Presenters::DownstreamPresenter.present(
      large_reverse_content_item,
      state_fallback_order: Adapters::ContentStore::DEPENDENCY_FALLBACK_ORDER
    )
    print "."
  end
  puts ""
}

large_forward_content_item = Queries::GetLatest.(ContentItemFilter.new(
  scope: ContentItem.where(content_id: '5eb84e7c-7631-11e4-a3cb-005056011aef')
).filter(state: 'published')).first

puts "Forward dependencies"
puts Benchmark.measure {
  10.times do |i|
    Rails.logger.debug "Iteration #{i}"
    Rails.logger.debug "-----------"
    Presenters::DownstreamPresenter.present(
      large_reverse_content_item,
      state_fallback_order: Adapters::ContentStore::DEPENDENCY_FALLBACK_ORDER
    )
    print "."
  end
  puts ""
}
