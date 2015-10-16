require "rails_helper"

RSpec.describe "Downstream timeouts", type: :request do
  context "/content" do
    let(:request_body) { content_item_without_access_limiting.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    behaves_well_when_draft_content_store_times_out
    behaves_well_when_live_content_store_times_out
  end

  context "/draft-content" do
    let(:request_body) { content_item_with_access_limiting.to_json }
    let(:request_path) { "/draft-content#{base_path}" }
    let(:request_method) { :put }

    behaves_well_when_draft_content_store_times_out
  end

  context "/v2/content" do
    let(:request_body) { v2_content_item.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    behaves_well_when_draft_content_store_times_out
  end

  context "/v2/links" do
    let(:request_body) { links_attributes.to_json }
    let(:request_path) { "/v2/links/#{content_id}" }
    let(:request_method) { :put }

    before do
      FactoryGirl.create(:live_content_item, v2_content_item.slice(*LiveContentItem::TOP_LEVEL_FIELDS))
      DraftContentItem.last.update!(access_limited: v2_content_item.fetch(:access_limited))
    end

    behaves_well_when_draft_content_store_times_out
  end
end
