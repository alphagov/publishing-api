class QueuePublisher
  def initialize(options = {})
    @noop = options[:noop]
    return if @noop

    @exchange_name = options.fetch(:exchange)
    @options = options.except(:exchange)
    @connection_mutex = Mutex.new
  end

  def connection
    @connection_mutex.synchronize do
      @connection ||= Bunny.new(ENV["RABBITMQ_URL"], @options)
      @connection_created_at ||= Time.zone.now
      @connection.start
    end
  end

  class PublishFailedError < StandardError
  end

  def send_message(edition, event_type: nil, routing_key: nil, persistent: true)
    return if @noop

    validate_edition(edition)
    routing_key ||= routing_key(edition, event_type)
    publish_message(routing_key, edition, content_type: "application/json", persistent:)
  end

  def routing_key(edition, event_type)
    normalised = edition.symbolize_keys
    event_type ||= normalised[:update_type]
    "#{normalised[:schema_name]}.#{event_type}"
  end

  def send_heartbeat
    return if @noop

    body = {
      timestamp: Time.zone.now.utc.iso8601,
      hostname: Socket.gethostname,
    }

    publish_message("heartbeat.major", body, content_type: "application/x-heartbeat", persistent: false)
  end

private

  def validate_edition(edition)
    validator = SchemaValidator.new(payload: edition, schema_type: :notification)
    unless validator.valid?
      Rails.logger.debug(
        {
          "message": "Message being sent to the queue does not match the notification schema",
          "error": validator.errors.to_s,
          "edition": edition,
        }.to_json,
      )
    end
  end

  def publish_message(routing_key, message_data, options = {})
    event_type = routing_key.split(".").last

    # We should only have one channel per thread
    channel = connection.create_channel
    begin
      # Enable publisher confirms, so we get acks back after publishes
      channel.confirm_select

      # Passive parameter ensures we don't create the exchange
      exchange = channel.topic(@exchange_name, passive: true)

      publish_options = options.merge(routing_key:)

      exchange.publish(message_data.to_json, publish_options)
      success = exchange.wait_for_confirms

      unless success
        GovukError.notify(
          PublishFailedError.new("Publishing message failed"),
          level: "error",
          extra: {
            routing_key:,
            message_body: message_data,
            options:,
          },
        )
      end
    rescue Timeout::Error => e
      log_publish_error(e, channel, routing_key:, event_type:)

      raise
    end
  ensure
    begin
      channel.close if channel&.open?
    rescue StandardError => e
      log_publish_error(e, channel, routing_key:, event_type:)
      # A failed channel close must not mask the original error, nor fail a
      # job whose publish already succeeded - a retry would re-publish and
      # duplicate the message. Log it and let the original outcome stand.
    end
  end

  def log_publish_error(error, channel, routing_key:, event_type:)
    # Reads @connection directly: going through the `connection` accessor
    # would call Session#start, which can attempt a reconnect and raise
    # from inside this logging path.
    Rails.logger.error(
      {
        "message": "Error publishing to RabbitMQ",
        "error": "#{error.class}: #{error.message}",
        "routing_key": routing_key,
        "event_type": event_type,
        "connection_open": @connection&.open?,
        "channel_open": channel.open?,
        "connection_status": @connection&.status,
        "connection_age_seconds": @connection_created_at ? Time.zone.now.to_i - @connection_created_at.to_i : nil,
        "broker_host": @connection&.transport&.host,
      }.to_json,
    )
  end
end
