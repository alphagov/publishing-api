RSpec::Matchers.define :be_fast_overall do |threshold:|
  description { "complete overall benchmark in under #{threshold}s" }

  match do |result|
    raise ArgumentError, "Must be called with an InstrumentationResult" unless result.is_a?(InstrumentationResult)

    @result = result
    result.overall_time < threshold
  end

  failure_message do |result|
    <<~MSG
      Expected overall time to be less than #{threshold}s, but was #{result.overall_time.round(3)}s.
      StackProf profile saved to: #{RSpec.current_example.metadata[:cpu_profile_path]}
      Open it at https://www.speedscope.app/
    MSG
  end
end
