require "rails_helper"

RSpec.describe "Downstream timeouts", type: :request do
  context "/content" do
    let(:request_body) { content_item_params.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    behaves_well_when_draft_content_store_times_out
    behaves_well_when_live_content_store_times_out
  end

  context "/draft-content" do
    let(:request_body) { content_item_params.to_json }
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
      live = FactoryGirl.create(:live_content_item, v2_content_item.slice(*ContentItem::TOP_LEVEL_FIELDS))
      draft = FactoryGirl.create(:draft_content_item, v2_content_item.slice(*ContentItem::TOP_LEVEL_FIELDS))

      FactoryGirl.create(:access_limit,
        content_item: draft,
        users: access_limit_params.fetch(:users),
      )
    end

    behaves_well_when_draft_content_store_times_out
    behaves_well_when_live_content_store_times_out
  end
end
