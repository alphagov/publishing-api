require_relative "./instrumentation_result"

module BenchmarkHelpers
  def instrument(&block)
    queries = []
    govspeak_renders = []
    sql_callback = lambda do |_name, start, finish, _id, payload|
      next if payload[:name].in?(%w[SCHEMA TRANSACTION])

      queries << { sql: payload[:sql], time: finish - start }
    end
    govspeak_callback = lambda do |_name, start, finish, _id, payload|
      govspeak_renders << { time: finish - start, **payload }
    end

    profile_data = nil
    time = Benchmark.realtime do
      ActiveSupport::Notifications.subscribed(govspeak_callback, "govspeak.to_html") do
        ActiveSupport::Notifications.subscribed(sql_callback, "sql.active_record") do
          profile_data = StackProf.run(mode: :wall, raw: true, &block)
        end
      end
    end

    InstrumentationResult.new(queries, govspeak_renders, time, profile_data).tap { record_instrumentation_result(_1) }
  end

private

  def record_instrumentation_result(instrumentation_result)
    example = RSpec.current_example
    spec_description = example.description

    filename = "#{spec_description.parameterize}.json"
    instrumentation_path = RSpec.configuration.benchmark_instrumentation_dir.join(filename)
    profile_path = RSpec.configuration.benchmark_profiles_dir.join(filename)

    File.write(instrumentation_path, instrumentation_result.report)
    File.write(profile_path, JSON.generate(instrumentation_result.profile))

    example.metadata[:instrumentation_result] = instrumentation_result
    example.metadata[:timings_report_path] = instrumentation_path.relative_path_from(Rails.root)
    example.metadata[:cpu_profile_path] = profile_path.relative_path_from(Rails.root)
  end
end
