RSpec::Matchers.define :be_fast_query do |threshold:|
  description { "be a SQL query that completes under #{threshold}s" }

  match do |query|
    raise ArgumentError, "Must be called with a hash containing :time and :sql" unless query.key?(:time) && query.key?(:sql)

    @query = query
    @threshold = threshold
    query[:time] < threshold
  end

  failure_message do |query|
    sql = query[:sql]
    plan = begin
      ActiveRecord::Base.connection.execute("EXPLAIN (ANALYZE, BUFFERS) #{sql}")
    rescue StandardError => e
      [["(Failed to EXPLAIN: #{e.message})"]]
    end

    test_name = RSpec.current_example.description.parameterize
    fingerprint = Digest::MD5.hexdigest(sql)
    sql_filepath = RSpec.configuration.benchmark_sql_log_dir.join("#{test_name}_#{fingerprint}.sql")
    File.write(sql_filepath, sql)

    pretty_plan = plan.respond_to?(:values) ? plan.values.map(&:first).join("\n") : plan.to_s

    query_plan_filepath = RSpec.configuration.benchmark_sql_log_dir.join("#{test_name}_#{fingerprint}.plan")
    File.write(query_plan_filepath, pretty_plan)

    <<~MSG
      Expected SQL query to complete in under #{@threshold} seconds, but took #{query[:time]}s.

      SQL query is in: #{sql_filepath.relative_path_from(Rails.root)}
      Query plan is in: #{query_plan_filepath.relative_path_from(Rails.root)}
    MSG
  end
end
