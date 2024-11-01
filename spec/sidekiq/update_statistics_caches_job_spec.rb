RSpec.describe UpdateStatisticsCachesJob, :perform do
  let(:documents_with_embeds) { create_list(:document, 4) }
  let(:documents_with_draft_embeds) { create_list(:document, 2) }
  let(:mock_page_views) do
    documents_with_embeds.map.with_index do |document, i|
      PageViewsService::PageView.new(path: document.live.base_path, page_views: i)
    end
  end
  let(:mock_page_views_service) { double(PageViewsService, call: mock_page_views) }

  before do
    documents_with_embeds.each do |document|
      create(:live_edition, document:, links_hash: { embed: [SecureRandom.uuid] })
    end

    documents_with_draft_embeds.each do |document|
      create(:draft_edition, document:, links_hash: { embed: [SecureRandom.uuid] })
    end

    _documents_without_embeds = create_list(:live_edition, 5, links_hash: {})

    allow(PageViewsService).to receive(:new).and_return(mock_page_views_service)
  end

  it "creates page views for all dependent content" do
    expect {
      UpdateStatisticsCachesJob.new.perform
    }.to change { StatisticsCache.count }.by(documents_with_embeds.count)

    expect_embeds_to_have_correct_data
  end

  it "upserts existing data" do
    documents_with_embeds.each do |document|
      StatisticsCache.create(document_id: document.id, unique_pageviews: 999)
    end

    expect {
      UpdateStatisticsCachesJob.new.perform
    }.to change { StatisticsCache.count }.by(0)

    expect_embeds_to_have_correct_data
  end

  context "when there are a large amount of editions to process" do
    let(:number_of_links) { (UpdateStatisticsCachesJob::BATCH_SIZE * 3) + 10 }
    let(:mock_edition) { build(:live_edition, base_path: "/something") }
    let(:mock_page_views) do
      [
        PageViewsService::PageView.new(path: mock_edition.base_path, page_views: 123),
      ]
    end
    let(:mock_links) { build_list(:link, number_of_links, edition: mock_edition) }

    before do
      allow(Link).to receive_message_chain(:includes, :where).and_return(mock_links)
      allow(StatisticsCache).to receive(:upsert_all)
    end

    it "processes editions in batches" do
      UpdateStatisticsCachesJob.new.perform

      expect(mock_page_views_service).to have_received(:call).exactly(4).times
      expect(StatisticsCache).to have_received(:upsert_all).exactly(4).times
    end
  end

  def expect_embeds_to_have_correct_data
    statistics_caches = StatisticsCache.all

    documents_with_embeds.each do |document|
      page_views_for_edition = mock_page_views.find { |view| view.path == document.live.base_path }
      statistics_cache_for_edition = statistics_caches.find { |cache| cache.document.id == document.id }
      expect(statistics_cache_for_edition).not_to be_nil
      expect(statistics_cache_for_edition&.unique_pageviews).to eq(page_views_for_edition&.page_views)
    end
  end
end
