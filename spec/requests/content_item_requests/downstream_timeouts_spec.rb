require "request_helper"

RSpec.describe "Downstream timeouts", type: :request do
  context "/content" do
    let(:content_item) { content_item_without_access_limiting }
    let(:request_path) { "/content#{base_path}" }

    behaves_well_when_draft_content_store_times_out
    behaves_well_when_live_content_store_times_out
  end

  context "/draft-content" do
    let(:content_item) { content_item_with_access_limiting }
    let(:request_path) { "/draft-content#{base_path}" }

    behaves_well_when_draft_content_store_times_out
  end
end
