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
      @connection.start
    end
  end

  class PublishFailedError < StandardError
  end

  def send_message(edition, event_type: nil, routing_key: nil, persistent: true)
    return if @noop

    validate_edition(edition)
    routing_key ||= routing_key(edition, event_type)
    publish_message(routing_key, edition, content_type: 'application/json', persistent: persistent)
  end

  def routing_key(edition, event_type)
    normalised = edition.symbolize_keys
    event_type ||= normalised[:update_type]
    "#{normalised[:schema_name]}.#{event_type}"
  end

  def send_heartbeat
    return if @noop

    body = {
      timestamp: Time.now.utc.iso8601,
      hostname: Socket.gethostname,
    }

    publish_message("heartbeat.major", body, content_type: "application/x-heartbeat", persistent: false)
  end

private

  def validate_edition(edition)
    validator = SchemaValidator.new(payload: edition, schema_type: :notification)
    if !validator.valid?
      Rails.logger.debug(
        {
          "message": "Message being sent to the queue does not match the notification schema",
          "error": validator.errors.to_s,
          "edition": edition,
        }.to_json
      )
    end
  end

  def publish_message(routing_key, message_data, options = {})
    # we should only have one channel per thread
    channel = connection.create_channel

    # Enable publisher confirms, so we get acks back after publishes
    channel.confirm_select

    # passive parameter ensures we don't create the exchange
    exchange = channel.topic(@exchange_name, passive: true)
    begin
      publish_options = options.merge(routing_key: routing_key)

      exchange.publish(message_data.to_json, publish_options)
      success = exchange.wait_for_confirms
      event_type = routing_key.split('.').last

      if success
        PublishingAPI.service(:statsd).increment("message-sent.#{event_type}")
      else
        GovukError.notify(
          PublishFailedError.new("Publishing message failed"),
          level: "error",
          extra: {
            routing_key: routing_key,
            message_body: message_data,
            options: options,
          }
        )
        PublishingAPI.service(:statsd).increment("message-send-failure.#{event_type}")
      end
    ensure
      channel.close if channel.open?
    end
  end
end
