RSpec.describe Types::NewsArticleType do
  describe ".document_types" do
    it "defines the document types for .resolve_type to distinguish the type from the generic Edition type" do
      expect(described_class.document_types).to eq(%w[
        government_response
        news_story
        press_release
        world_news_story
      ])
    end
  end
end
