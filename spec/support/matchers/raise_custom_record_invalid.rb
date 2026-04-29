RSpec::Matchers.define :raise_custom_record_invalid do |expected_code, expected_message = nil|
  supports_block_expectations

  match do |block|
    block.call
    false
  rescue CustomRecordInvalid => e
    @actual_error = e

    code_matches = e.error_code == expected_code

    message_matches =
      expected_message.nil? ||
      (expected_message.is_a?(Regexp) ? e.message.match?(expected_message) : e.message == expected_message)

    code_matches && message_matches
  rescue StandardError => e
    @wrong_error = e
    false
  end

  failure_message do
    if @wrong_error
      "expected CustomRecordInvalid with code #{expected_code}, but got #{@wrong_error.class}: #{@wrong_error.message}"
    elsif @actual_error
      msg = "expected error_code #{expected_code}, got #{@actual_error.error_code}"
      if expected_message
        msg += " and message #{expected_message.inspect}, got #{@actual_error.message.inspect}"
      end
      msg
    else
      "expected CustomRecordInvalid with code #{expected_code}, but nothing was raised"
    end
  end
end
