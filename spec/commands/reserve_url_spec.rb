require "rails_helper"
require "govuk/client/test_helpers/url_arbiter"

RSpec.describe Commands::ReserveUrl do
  include GOVUK::Client::TestHelpers::URLArbiter

  describe "call" do
    before do
      stub_default_url_arbiter_responses
    end

    context "with a new base_path" do
      let(:payload) {
        { base_path: "/foo", publishing_app: "Foo" }
      }

      it "successfully reserves the path" do
        expect(described_class.call(payload)).to be_a Commands::Success
      end
    end

    context "with an invalid payload" do
      it "returns a CommandError" do
        expect {
          described_class.call({ base_path: "///" })
        }.to raise_error CommandError
      end
    end
  end
end
