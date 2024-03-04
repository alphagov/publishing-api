#!/usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)
require "benchmark"

require "stackprof"

ministers_index_content_id = "324e4708-2285-40a0-b3aa-cb13af14ec5f"
link_expansion = LinkExpansion.by_content_id(ministers_index_content_id)
link_graph = link_expansion.link_graph
content_ids = link_graph.links_content_ids

StackProf.run(mode: :wall, raw: true, out: "tmp/link_expansion_ministers_index.dump") do
  time = Benchmark.realtime do
    Queries::GetEditionIdsWithFallbacks.call(
      content_ids,
      content_stores: %w[live draft],
      locale_fallback_order: ["en"],
      state_fallback_order: %i[draft published withdrawn],
    )
  end
  puts time
end
