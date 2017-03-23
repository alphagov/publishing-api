class QueuePublisher
  def initialize(options = {})
    @noop = options[:noop]
    return if @noop

    @exchange_name = options.fetch(:exchange)
    @options = options.except(:exchange)
  end

  def connection
    @connection ||= Bunny.new(@options)
    @connection.start
  end

  class PublishFailedError < StandardError
  end

  def send_message(edition, routing_key: nil)
    return if @noop
    routing_key ||= routing_key(edition)
    publish_message(routing_key, edition, content_type: 'application/json', persistent: true)
  end

  def routing_key(edition)
    normalised = edition.symbolize_keys
    "#{normalised[:schema_name]}.#{normalised[:update_type]}"
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
      if !success
        Airbrake.notify(
          PublishFailedError.new("Publishing message failed"),
          parameters: {
            routing_key: routing_key,
            message_body: message_data,
            options: options,
          }
        )
      end
    ensure
      channel.close if channel.open?
    end
  end
end
