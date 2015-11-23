require "rails_helper"

RSpec.describe ContentStoreWorker do
  before do
    stub_request(:put, "http://content-store.dev.gov.uk/content/foo").
      to_return(status: status, body: {}.to_json)
  end

  def do_request
    subject.perform(
      content_store: "Adapters::ContentStore",
      base_path: "/foo",
      payload: { some: "payload" }
    )
  end

  expectations = {
    200 => { raises_error: false, logs_to_airbrake: false },
    202 => { raises_error: false, logs_to_airbrake: false },
    400 => { raises_error: false, logs_to_airbrake: true },
    409 => { raises_error: false, logs_to_airbrake: true },
    500 => { raises_error: true, logs_to_airbrake: false },
  }

  expectations.each do |status, expectation|
    context "when the content store responds with a #{status}" do
      let(:status) { status }

      if expectation.fetch(:raises_error)
        it "raises an error" do
          expect { do_request }.to raise_error(CommandError)
        end
      else
        it "does not raise an error" do
          expect { do_request }.to_not raise_error
        end
      end

      if expectation.fetch(:logs_to_airbrake)
        it "logs the response to airbrake" do
          expect(Airbrake).to receive(:notify_or_ignore)
          do_request rescue CommandError
        end
      else
        it "does not log the response to airbrake" do
          expect(Airbrake).to_not receive(:notify_or_ignore)
          do_request rescue CommandError
        end
      end
    end
  end
end
