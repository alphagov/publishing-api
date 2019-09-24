require "rails_helper"

RSpec.describe QueuePublisher do
  context "real mode" do
    let(:options) do
      {
        host: "rabbitmq.example.com",
        port: 5672,
        user: "test_user",
        pass: "super_secret",
        recover_from_connection_close: true,
        exchange: "test_exchange",
      }
    end
    let(:queue_publisher) { QueuePublisher.new(options) }

    let(:mock_session) { instance_double("Bunny::Session", create_channel: mock_channel) }
    let(:mock_channel) { instance_double("Bunny::Channel", confirm_select: nil, topic: mock_exchange, open?: false) }
    let(:mock_exchange) { instance_double("Bunny::Exchange", publish: nil, wait_for_confirms: true) }
    before :each do
      allow(Bunny).to receive(:new) { mock_session }
      allow(mock_session).to receive(:start) { mock_session }
    end

    describe "setting up the connection etc" do
      it "connects to rabbitmq using the given parameters" do
        expect(Bunny).to receive(:new).with(anything, options.except(:exchange)).and_return(mock_session)
        expect(mock_session).to receive(:start)

        queue_publisher.connection
      end

      it "does not raise an exception from the constructor if connecting to rabbitmq fails" do
        # This is to ensure the application can still boot when rabbitmq is unavailable.
        allow(Bunny).to receive(:new).and_raise(Bunny::TCPConnectionFailedForAllHosts)

        expect {
          queue_publisher
        }.not_to raise_error
      end
    end

    describe "sending a message" do
      let(:content_item) {
        {
          base_path: "/vat-rates",
          title: "VAT Rates",
          description: "VAT rates for goods and services",
          document_type: "nonexistent-schema",
          schema_name: "answer",
          publishing_app: "publisher",
          locale: "en",
          details: {
            app: "or format",
            specific: "data...",
          },
          update_type: "major",
        }
      }

      it "sends the json representation of the item on the message queue" do
        expect(mock_exchange).to receive(:publish).with(content_item.to_json, hash_including(content_type: "application/json"))

        queue_publisher.send_message(content_item)
      end

      it "uses a routing key of schema_name.update_type" do
        expect(mock_exchange).to receive(:publish).with(anything, hash_including(routing_key: "#{content_item[:schema_name]}.#{content_item[:update_type]}"))

        queue_publisher.send_message(content_item)
      end

      context "edition using string keys" do
        let(:content_item) { super().stringify_keys }

        it "correctly calculates routing key" do
          expect(mock_exchange).to receive(:publish).with(anything, hash_including(routing_key: "#{content_item['schema_name']}.#{content_item['update_type']}"))

          queue_publisher.send_message(content_item)
        end
      end

      it "allows the routing key to be overridden" do
        custom_routing_key = "my_routing.key"
        expect(mock_exchange).to receive(:publish).with(anything, hash_including(routing_key: custom_routing_key))

        queue_publisher.send_message(content_item, routing_key: custom_routing_key)
      end

      it "sends the message as persistent" do
        expect(mock_exchange).to receive(:publish).with(anything, hash_including(persistent: true))

        queue_publisher.send_message(content_item)
      end

      describe "error handling" do
        context "when message delivery is not acknowledged positively" do
          before :each do
            allow(mock_exchange).to receive(:wait_for_confirms).and_return(false)
          end

          it "notifies errbit of the error" do
            expect(GovukError).to receive(:notify).with(an_instance_of(QueuePublisher::PublishFailedError), anything)

            queue_publisher.send_message(content_item)
          end

          it "includes the message details in the notification" do
            expect(GovukError).to receive(:notify).with(
              anything,
              level: "error",
              extra: {
                message_body: content_item,
                routing_key: "#{content_item[:schema_name]}.#{content_item[:update_type]}",
                options: { content_type: "application/json", persistent: true },
              },
            )

            queue_publisher.send_message(content_item)
          end
        end
      end
    end

    describe "sending a heartbeat message" do
      before :each do
        allow(Socket).to receive(:gethostname) { "example-hostname" }
      end

      it "sends a heartbeat message" do
        Timecop.freeze do
          expected_data = {
            timestamp: Time.now.utc.iso8601,
            hostname: "example-hostname",
          }
          expect(mock_exchange).to receive(:publish).with(expected_data.to_json, hash_including(content_type: "application/x-heartbeat"))

          queue_publisher.send_heartbeat
        end
      end

      it "uses a routing key of 'heartbeat.major'" do
        expect(mock_exchange).to receive(:publish).with(anything, hash_including(routing_key: "heartbeat.major"))

        queue_publisher.send_heartbeat
      end

      it "sends the message as non-persistent" do
        expect(mock_exchange).to receive(:publish).with(anything, hash_including(persistent: false))

        queue_publisher.send_heartbeat
      end
    end
  end

  context "noop mode" do
    subject { QueuePublisher.new(noop: true) }

    it "does not send messages" do
      expect_any_instance_of(Bunny::Exchange).not_to receive(:publish)

      subject.send_message(:something)
    end

    it "does not sent heartbeats" do
      expect_any_instance_of(Bunny::Exchange).not_to receive(:publish)

      subject.send_heartbeat
    end
  end
end
