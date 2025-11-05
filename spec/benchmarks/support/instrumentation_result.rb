InstrumentationResult = Data.define(:queries, :govspeak_renders, :overall_time, :profile) do
  def report
    JSON.pretty_generate(
      overall_time:,
      sql_time: queries.sum { _1[:time] },
      queries:,
      govspeak_time: govspeak_renders.sum { _1[:time] },
      govspeak_renders:,
    )
  end

  def summary
    sql_time, sql_summary = summarise_times(queries)
    govspeak_time, govspeak_summary = summarise_times(govspeak_renders)
    other_time = overall_time - govspeak_time - sql_time

    [
      "Overall time #{overall_time.round(3)}",
      "SQL #{sql_time.round(3)}, Govspeak #{govspeak_time.round(3)}, Other #{other_time.round(3)}",
      "#{queries.count} SQL queries (#{sql_summary})",
      "#{govspeak_renders.count} Govspeak renders (#{govspeak_summary})",
    ].join(" | ")
  end

private

  def summarise_times(results)
    times = results.map { |result| result[:time] }
    total_time = times.sum
    summary = if times.any?
                [
                  "max: #{times.max.round(3)}",
                  "min: #{times.min.round(3)}",
                  "avg: #{(total_time / times.count).round(3)}",
                ].join(", ")
              end
    [total_time, summary]
  end
end
