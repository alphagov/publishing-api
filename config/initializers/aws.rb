require "aws-sdk-core"

# rubocop:disable Rails/SaveBang
Aws.config.update(
  logger: ::Rails.logger,
  region: ENV["S3_EXPORT_REGION"] || "eu-west-1",
)

if ENV["EVENT_LOG_AWS_ACCESS_ID"]
  Aws.config.update(
    credentials: Aws::Credentials.new(
      ENV["EVENT_LOG_AWS_ACCESS_ID"],
      ENV["EVENT_LOG_AWS_SECRET_KEY"],
    ),
  )
end
# rubocop:enable Rails/SaveBang
