require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.configure do |c|
  c.extend RequestHelpers
end

RSpec.describe "Content item requests", :type => :request do
  include GOVUK::Client::TestHelpers::URLArbiter
  include MessageQueueHelpers

  let(:base_path) {
    "/vat-rates"
  }

  let(:content_item) {
    {
      base_path: base_path,
      title: "VAT rates",
      description: "VAT rates for goods and services",
      format: "guide",
      need_ids: ["100123", "100124"],
      public_updated_at: "2014-05-14T13:00:06Z",
      publishing_app: "mainstream_publisher",
      rendering_app: "mainstream_frontend",
      locale: "en",
      details: {
        body: "<p>Soemthing about VAT</p>\n",
      },
      routes: [
        {
          path: "/vat-rates",
          type: "exact",
        }
      ],
      update_type: "major",
    }
  }

  let(:content_item_with_access_limiting) {
    content_item.merge(
      access_limited: {
        users: [
          "f17250b0-7540-0131-f036-005056030202",
          "74c7d700-5b4a-0131-7a8e-005056030037",
        ],
      },
    )
  }

  let(:stub_json_response) {
    double(:json_response, body: "", headers: {
      content_type: "application/json; charset=utf-8",
    })
  }

  before do
    stub_default_url_arbiter_responses
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "PUT /content" do
    check_url_registration_happens
    check_url_registration_failures
    check_200_response
    check_400_on_invalid_json
    check_content_type_header
    check_draft_content_store_502_suppression

    before :all do
      @config = YAML.load_file(Rails.root.join("config", "rabbitmq.yml"))[Rails.env].symbolize_keys
      @old_publisher = PublishingAPI.services(:queue_publisher)
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

    def put_content_item(body: content_item.to_json)
      put "/content/vat-rates", body
    end

    it "sends to draft content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .ordered

      put_content_item
    end

    it "sends to live content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(stub_json_response)
        .ordered

      put_content_item
    end

    it "strips access limiting metadata from the document" do
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )

      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(stub_json_response)

      put_content_item(body: content_item_with_access_limiting.to_json)
    end

    it 'should place a message on the queue using the private representation of the content item' do
      put_content_item
      _, properties, payload = wait_for_message_on(@queue)
      expect(properties[:content_type]).to eq('application/json')
      message = JSON.parse(payload)
      expect(message['title']).to eq('VAT rates')

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
      redirect_content_item = {
        base_path: "/crb-checks",
        format: "redirect",
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "publisher",
        redirects: [
          {
            path: "/crb-checks",
            type: "prefix",
            destination: "/dbs-checks"
          },
        ],
        update_type: "major",
      }
      put_content_item(body: redirect_content_item.to_json)
      delivery_info, _, _ = wait_for_message_on(@queue)
      expect(delivery_info.routing_key).to eq('redirect.major')
    end
  end

  describe "PUT /draft-content" do
    check_url_registration_happens
    check_url_registration_failures
    check_200_response
    check_400_on_invalid_json
    check_content_type_header
    check_draft_content_store_502_suppression

    def put_content_item(body: content_item.to_json)
      put "/draft-content/vat-rates", body
    end

    it "sends to draft content store after registering the URL" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).ordered
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item,
        )
        .and_return(stub_json_response)
        .ordered

      put_content_item
    end

    it "does not send anything to the live content store" do
      expect(PublishingAPI.services(:live_content_store)).to receive(:put_content_item).never
      expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)

      put_content_item
    end

    it "leaves access limiting metadata in the document" do
      expect(PublishingAPI.services(:draft_content_store)).to receive(:put_content_item)
        .with(
          base_path: base_path,
          content_item: content_item_with_access_limiting,
        )
        .and_return(stub_json_response)

      put_content_item(body: content_item_with_access_limiting.to_json)
    end

    it "doesn't send any messages" do
      expect(PublishingAPI.services(:queue_publisher)).not_to receive(:send_message)

      put_content_item
    end
  end
end
