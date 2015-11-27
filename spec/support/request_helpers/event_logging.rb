require "json"

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

      context "with the authenticated user header set" do
        it "logs the user uuid from the header" do
          do_request(headers: {
            "HTTP_X_GOVUK_AUTHENTICATED_USER" => "user-uuid-1234"
          })

          expect(response.status).to eq(200)

          expect(Event.count).to eq(1)
          expect(Event.first.user_uid).to eq("user-uuid-1234")
        end
      end
    end

    def does_not_log_event
      it "does not log an event in the event log" do
        do_request

        expect(Event.count).to eq(0)
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::EventLogging, :type => :request
