module RequestHelpers
  module DownstreamTimeouts
    def behaves_well_when_draft_content_store_times_out
      context "draft content store times out" do
        before do
          stub_request(:put, Plek.find('draft-content-store') + "/content#{base_path}").to_timeout
        end

        it "does not log an event in the event log" do
          do_request

          expect(Event.count).to eq(0)
        end

        it "returns an error" do
          do_request

          expect(response.status).to eq(500)
          expect(JSON.parse(response.body)).to eq(
            "error" => {
              "code" => 500,
              "message" => "Unexpected error from the downstream application: GdsApi::TimedOutException"
            }
          )
        end
      end
    end

    def behaves_well_when_live_content_store_times_out
      context "content store times out" do
        before do
          stub_request(:put, Plek.find('content-store') + "/content#{base_path}").to_timeout
        end

        it "does not log an event in the event log" do
          do_request

          expect(Event.count).to eq(0)
        end

        it "returns an error" do
          do_request

          expect(response.status).to eq(500)
          expect(JSON.parse(response.body)).to eq(
            "error" => {
              "code" => 500,
              "message" => "Unexpected error from the downstream application: GdsApi::TimedOutException"
            }
          )
        end
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::DownstreamTimeouts, :type => :request
