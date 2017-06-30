require "rails_helper"

RSpec.describe ExpandedLinkSetCacheWorker do
  describe "perform" do
    let(:content_id) { edition.document.content_id }
    let(:edition) { FactoryGirl.create(:live_edition) }
    let!(:fr_document) { FactoryGirl.create(:document, content_id: content_id, locale: "fr") }
    let(:link) { SecureRandom.uuid }
    let!(:link_set) do
      FactoryGirl.create(:link_set,
        content_id: content_id,
        links: [
          FactoryGirl.create(:link,
            link_type: "topics",
            target_content_id: edition.content_id,
          )
        ]
      )
    end

    it "caches expanded links keyed by content id and locale" do
      expect(Rails.cache).to receive(:write)
        .with(["expanded-link-set", content_id, "en", false],
              a_hash_including(topics: [a_hash_including(content_id: content_id)]))

      expect(Rails.cache).to receive(:write)
        .with(["expanded-link-set", content_id, "fr", false],
              a_hash_including(topics: [a_hash_including(content_id: content_id)]))

      subject.perform(content_id)
    end
  end
end
