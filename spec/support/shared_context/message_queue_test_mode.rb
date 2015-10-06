RSpec.shared_context "using the message queue in test mode" do
  before :all do
    @config = YAML.load_file(Rails.root.join("config", "rabbitmq.yml"))[Rails.env].symbolize_keys
    @old_publisher = PublishingAPI.service(:queue_publisher)
    PublishingAPI.register_service(name: :queue_publisher, client: QueuePublisher.new(@config))
  end

  after :all do
    PublishingAPI.register_service(name: :queue_publisher, client: @old_publisher)
  end

  around :each do |example|
    conn = Bunny.new(@config)
    conn.start
    read_channel = conn.create_channel
    ex = read_channel.topic(@config.fetch(:exchange), passive: true)
    @queue = read_channel.queue("", :exclusive => true)
    @queue.bind(ex, routing_key: '#')

    example.run

    read_channel.close
  end
end
