class TimedFeature
  def self.check!(owner:, expires:)
    return unless Date.today > Date.parse(expires)

    message = <<~HEREDOC
      Expired feature!

      The feature you are attempting to use has expired.

      Please ask #{owner} to remove the code or extend the feature period.
    HEREDOC

    raise CommandError.new(
      code: 410,
      error_details: { error: { code: 410, message: message } },
    )
  end
end
