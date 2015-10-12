module RequestHelpers
  module EventLogging
    def logs_event(event_class_name, expected_payload_proc:)
      it "logs a '#{event_class_name}' event in the event log" do
        do_request

        expect(response.status).to eq(200)

        expect(Event.count).to eq(1)
        expect(Event.first.action).to eq(event_class_name)
        expect(Event.first.user_uid).to eq(nil)

        expect(Event.first.payload).to eq(instance_exec(&expected_payload_proc))
      end
    end

    def does_not_log_event
      it "does not log an event in the event log" do
        do_request

        expect(Event.count).to eq(0)
        expect(response.status).to eq(422)
        expect(response.body).to eq(error_details.to_json)
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::EventLogging, :type => :request
