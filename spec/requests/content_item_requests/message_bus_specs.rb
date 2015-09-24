require "request_helper"

RSpec.describe "Message bus", type: :request do
  include MessageQueueHelpers

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

  context "/content" do
    let(:content_item) { content_item_without_access_limiting }
    let(:request_path) { "/content#{base_path}" }

    it 'should place a message on the queue using the private representation of the content item' do
      put_content_item

      _, properties, payload = wait_for_message_on(@queue)
      expect(properties[:content_type]).to eq('application/json')

      message = JSON.parse(payload)
      expect(message['title']).to eq('VAT rates')
      expect(message['base_path']).to eq(base_path)

      # Check for a private field
      expect(message).to have_key('publishing_app')
    end

    it 'should include the update_type in the output json' do
      put_content_item

      _, _, payload = wait_for_message_on(@queue)
      message = JSON.parse(payload)
      expect(message).to have_key('update_type')
    end

    it 'routing key depends on format and update type' do
      put_content_item(body: content_item.merge(update_type: "minor").to_json)
      delivery_info, _, payload = wait_for_message_on(@queue)
      expect(delivery_info.routing_key).to eq('guide.minor')

      put_content_item(body: content_item.merge(format: "detailed_guide").to_json)
      delivery_info, _, payload = wait_for_message_on(@queue)
      expect(delivery_info.routing_key).to eq('detailed_guide.major')
    end

    it 'publishes a message for a redirect update' do
      put_content_item(body: redirect_content_item.to_json)

      delivery_info, _, _ = wait_for_message_on(@queue)
      expect(delivery_info.routing_key).to eq('redirect.major')
    end
  end

  context "/draft-content" do
    let(:content_item) { content_item_with_access_limiting }
    let(:request_path) { "/draft-content#{base_path}" }

    it "doesn't send any messages" do
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      put_content_item
    end
  end
end
