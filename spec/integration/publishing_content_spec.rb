RSpec.describe "POST /v2/content/:content_id/publish" do
  let(:content_id) { SecureRandom.uuid }
  let!(:draft_item) do
    create(
      :draft_edition,
      document: create(:document, content_id:),
      base_path: "/foo",
    )
  end

  before do
    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{draft_item.base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{draft_item.base_path}")
      .to_return(status: 200)
  end

  context "when a draft item has embedded content" do
    let(:mock_page_view) do
      PageViewsService::PageView.new(path: draft_item.base_path, page_views: 123)
    end
    let(:mock_page_views_service) { double(PageViewsService, call: [mock_page_view]) }

    before do
      draft_item.links.create!({ link_type: "embed", target_content_id: SecureRandom.uuid })
    end

    it "creates a statistics cache item" do
      expect(PageViewsService).to receive(:new).and_return(mock_page_views_service)

      post "/v2/content/#{content_id}/publish", params: {}.to_json

      expect(response).to be_ok, response.body

      cache_item = draft_item.document.reload.statistics_cache

      expect(cache_item).not_to be_nil
      expect(cache_item.document_id).to eq(draft_item.document.id)
      expect(cache_item.unique_pageviews).to eq(mock_page_view.page_views)
    end
  end

  context "when there is no embedded content associated with the item" do
    it "does not create a statistics cache item" do
      post "/v2/content/#{content_id}/publish", params: {}.to_json

      expect(response).to be_ok, response.body

      cache_item = draft_item.document.reload.statistics_cache

      expect(cache_item).to be_nil
    end
  end
end
