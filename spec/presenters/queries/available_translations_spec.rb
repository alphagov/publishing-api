require 'rails_helper'

RSpec.describe Presenters::Queries::AvailableTranslations do
  subject(:translations) {
    described_class.new(
      link_set.content_id,
      state_fallback_order,
    ).translations[:available_translations]
  }

  def create_content_item(base_path, state = "published", locale = "en", version = 1)
    FactoryGirl.create(:content_item,
      document: Document.find_or_create_by(content_id: link_set.content_id, locale: locale),
      base_path: base_path,
      state: state,
      content_store: state == 'draft' ? 'draft' : 'live',
      user_facing_version: version,
    )
  end

  let(:link_set) { FactoryGirl.create(:link_set) }

  context "with items in a matching state" do
    let(:state_fallback_order) { [:published] }

    before do
      create_content_item("/a", "published")
      create_content_item("/a.ar", "published", "ar")
      create_content_item("/a.es", "published", "es")
    end

    it "returns all the items" do
      expect(translations).to match_array([
        a_hash_including(base_path: "/a", locale: "en"),
        a_hash_including(base_path: "/a.ar", locale: "ar"),
        a_hash_including(base_path: "/a.es", locale: "es"),
      ])
    end
  end

  context "with items in more than one state" do
    let!(:en) { create_content_item("/a", "published") }
    let!(:ar) { create_content_item("/a.ar", "draft", "ar") }
    let!(:es) { create_content_item("/a.es", "published", "es") }

    context "with multiple states in the fallback order" do
      let(:state_fallback_order) { [:draft, :published] }

      it "returns items in all states in the fallback order" do
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en"),
          a_hash_including(base_path: "/a.ar", locale: "ar"),
          a_hash_including(base_path: "/a.es", locale: "es"),
        ])
      end

      it "takes the item in the first matching state" do
        es.update_attribute("title", "no habla español")
        draft_es = create_content_item("/a.es", "draft", "es", 2)
        draft_es.update_attribute("title", "mais on parle français")
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en"),
          a_hash_including(base_path: "/a.ar", locale: "ar"),
          a_hash_including(base_path: "/a.es", locale: "es", title: "mais on parle français"),
        ])
      end
    end

    context "with a single state in the fallback order" do
      let(:state_fallback_order) { [:published] }

      it "does not return items with states not in the fallback order" do
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en"),
          a_hash_including(base_path: "/a.es", locale: "es"),
        ])
      end
    end
  end
end
