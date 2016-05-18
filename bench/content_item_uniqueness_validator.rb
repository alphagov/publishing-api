# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)
require 'benchmark'

max_content_id = ContentItem.maximum(:id)

random_ids = 100.times.map { rand(max_content_id - 1) + 1 }

puts Benchmark.measure {
  random_ids.each do |id|
    state = State.where(content_item_id: id).first
    if state
      ContentItemUniquenessValidator.new.validate(state)
      print "."
    else
      print "x"
    end
  end
  puts ""
}
