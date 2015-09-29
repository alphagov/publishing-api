require "request_helper"

RSpec.describe "Event logging", type: :request do
  context "/content" do
    let(:content_item) { content_item_without_access_limiting }
    let(:request_path) { "/content#{base_path}" }

    logs_event('PutContentWithLinks')
  end

  context "/draft-content" do
    let(:content_item) { content_item_with_access_limiting }
    let(:request_path) { "/draft-content#{base_path}" }

    logs_event('PutDraftContentWithLinks')
  end
end
