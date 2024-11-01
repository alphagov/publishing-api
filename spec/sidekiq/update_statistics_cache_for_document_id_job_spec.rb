RSpec.describe UpdateStatisticsCacheForDocumentIdJob, :perform do
  let(:document) { edition.document }
  let(:edition) { create(:live_edition, document: create(:document)) }
  let(:mock_page_view) do
    PageViewsService::PageView.new(path: document.live.base_path, page_views: 123)
  end
  let(:mock_page_views_service) { double(PageViewsService, call: [mock_page_view]) }

  before do
    allow(PageViewsService).to receive(:new).and_return(mock_page_views_service)
    allow(Rails.logger).to receive(:info)
  end

  it "creates a statistics cache for the document if one does not exist" do
    expect { described_class.new.perform(document.id) }.to change { StatisticsCache.count }.by(1)

    statistics_cache = document.reload.statistics_cache

    expect(statistics_cache).not_to be_nil
    expect(statistics_cache&.document&.id).to eq(document.id)
    expect(statistics_cache&.unique_pageviews).to eq(mock_page_view.page_views)
  end

  it "updates a statistics cache if one already exists for the document" do
    create(:statistics_cache, document:, unique_pageviews: 999)
    expect { described_class.new.perform(document.id) }.to change { StatisticsCache.count }.by(0)

    statistics_cache = document.reload.statistics_cache

    expect(statistics_cache).not_to be_nil
    expect(statistics_cache&.document&.id).to eq(document.id)
    expect(statistics_cache&.unique_pageviews).to eq(mock_page_view.page_views)
  end

  context "if there is no data available" do
    let(:mock_page_views_service) { double(PageViewsService, call: []) }

    it "does nothing and logs a message" do
      expect { described_class.new.perform(document.id) }.to change { StatisticsCache.count }.by(0)

      expect(Rails.logger).to have_received(:info).with("No data found for #{document.live.base_path} - skipping")
    end
  end

  context "if there is no data returned for the document" do
    # This shouldn't happen, but we should at least add a test, just in case we get back incorrect data for some reason
    let(:mock_page_view) do
      PageViewsService::PageView.new(path: "/something-else", page_views: 123)
    end

    it "does nothing and logs a message" do
      expect { described_class.new.perform(document.id) }.to change { StatisticsCache.count }.by(0)

      expect(Rails.logger).to have_received(:info).with("No data found for #{document.live.base_path} - skipping")
    end
  end
end
