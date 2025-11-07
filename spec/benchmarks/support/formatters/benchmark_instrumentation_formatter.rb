RSpec::Support.require_rspec_core "formatters/base_text_formatter"
RSpec::Support.require_rspec_core "formatters/console_codes"

# NOTE: forked from RSpec's DocumentationFormatter:
#   https://github.com/rspec/rspec/blob/0c37a88d/rspec-core/lib/rspec/core/formatters/documentation_formatter.rb
class BenchmarkInstrumentationFormatter < RSpec::Core::Formatters::BaseTextFormatter
  RSpec::Core::Formatters.register self, :example_started, :example_group_started, :example_group_finished,
                                   :example_passed, :example_pending, :example_failed

  def initialize(output)
    super
    @group_level = 0

    @example_running = false
    @messages = []
  end

  def example_started(_notification)
    @example_running = true
  end

  def example_group_started(notification)
    output.puts if @group_level == 0
    output.puts "#{current_indentation}#{notification.group.description.strip}"

    @group_level += 1
  end

  def example_group_finished(_notification)
    @group_level -= 1 if @group_level > 0
  end

  def example_passed(passed)
    output.puts passed_output(passed.example)

    flush_messages
    @example_running = false
  end

  def example_pending(pending)
    output.puts pending_output(pending.example,
                               pending.example.execution_result.pending_message)

    flush_messages
    @example_running = false
  end

  def example_failed(failure)
    output.puts failure_output(failure.example)

    flush_messages
    @example_running = false
  end

  def message(notification)
    if @example_running
      @messages << notification.message
    else
      output.puts "#{current_indentation}#{notification.message}"
    end
  end

private

  def flush_messages
    @messages.each do |message|
      output.puts "#{current_indentation(1)}#{message}"
    end

    @messages.clear
  end

  def passed_output(example)
    [
      RSpec::Core::Formatters::ConsoleCodes.wrap("#{current_indentation}#{example.description.strip}", :success),
      instrumentation_output(example),
    ].join("\n")
  end

  def pending_output(example, message)
    RSpec::Core::Formatters::ConsoleCodes.wrap(
      "#{current_indentation}#{example.description.strip} (PENDING: #{message})",
      :pending,
    )
  end

  def failure_output(example)
    [
      RSpec::Core::Formatters::ConsoleCodes.wrap(
        "#{current_indentation}#{example.description.strip} (FAILED - #{next_failure_index})",
        :failure,
      ),
      instrumentation_output(example),
    ].join("\n")
  end

  def instrumentation_output(example)
    result = example.metadata[:instrumentation_result]

    timings_report_path = example.metadata[:timings_report_path]
    cpu_profile_path = example.metadata[:cpu_profile_path]
    [
      ("#{current_indentation(1)}#{result.summary}" if result),
      ("#{current_indentation(2)}Timings report: #{timings_report_path}" if timings_report_path),
      ("#{current_indentation(2)}CPU Profile: #{cpu_profile_path}" if cpu_profile_path),
    ].compact.join("\n")
  end

  def next_failure_index
    @next_failure_index ||= 0
    @next_failure_index += 1
  end

  def current_indentation(offset = 0)
    "  " * (@group_level + offset)
  end
end
