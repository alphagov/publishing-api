require "rails_helper"

RSpec.describe "Event logging", type: :request do
  context "/content" do
    let(:request_body) { content_item_without_access_limiting.to_json }
    let(:request_path) { "/content#{base_path}" }

    logs_event('PutContentWithLinks', expected_payload: RequestHelpers::Mocks.content_item_without_access_limiting)
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }

    logs_event('PutDraftContentWithLinks', expected_payload: RequestHelpers::Mocks.content_item_with_access_limiting)
  end
end
