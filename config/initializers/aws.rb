require "aws-sdk-core"

# rubocop:disable Rails/SaveBang
Aws.config.update(
  logger: ::Rails.logger,
  region: ENV["S3_EXPORT_REGION"] || "eu-west-1",
  credentials: Aws::Credentials.new(ENV["EVENT_LOG_AWS_ACCESS_ID"] || "id", ENV["EVENT_LOG_AWS_SECRET_KEY"] || "key"),
)
# rubocop:enable Rails/SaveBang
