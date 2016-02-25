module RequestHelpers
  module DownstreamRequests
    def sends_to_draft_content_store
      it "sends to draft content store" do
        allow(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store
              .merge(payload_version: anything)
          )

        do_request

        expect(response).to be_ok, response.body
      end
    end

    def sends_to_live_content_store
      it "sends to live content store" do
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).with(anything)

        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_live_content_store
              .merge(payload_version: anything)
          )

        do_request

        expect(response).to be_ok, response.body
      end
    end

    def does_not_send_to_live_content_store
      it "does not send anything to the live content store" do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        do_request
      end
    end

    def does_not_send_to_draft_content_store
      it "does not send anything to the draft content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)

        do_request
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::DownstreamRequests, type: :request
