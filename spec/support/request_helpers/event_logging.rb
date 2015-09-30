module RequestHelpers
  module EventLogging
    def logs_event(event_class_name)
      it "logs a '#{event_class_name}' event in the event log" do
        put_content_item

        expect(Event.count).to eq(1)
        expect(Event.first.action).to eq(event_class_name)
        expect(Event.first.user_uid).to eq(nil)

        expected_payload = content_item.merge("base_path" => base_path).deep_stringify_keys
        expect(Event.first.payload).to eq(expected_payload)
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::EventLogging, :type => :request
