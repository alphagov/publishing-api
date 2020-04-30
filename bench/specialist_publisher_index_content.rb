# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)

require "benchmark"

abort "Refusing to run outside of development" unless Rails.env.development?

document_types = Edition
  .where(publishing_app: "specialist-publisher")
  .distinct.pluck(:document_type)

document_types.each do |document_type|
  puts document_type.to_s

  tms = Benchmark.measure do
    10.times do
      Queries::GetContentCollection.new(
        document_types: document_type,
        fields: %w[base_path content_id last_edited_at title publication_state state_history],
        filters: { publishing_app: "specialist-publisher" },
        pagination: Pagination.new(per_page: 50, page: 1, order: "-last_edited_at"),
      ).call
      print "."
    end
  end
  puts tms
  puts ""
end
