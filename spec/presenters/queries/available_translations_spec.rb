require "rails_helper"

RSpec.describe Presenters::Queries::AvailableTranslations do
  subject(:translations) do
    described_class
      .by_content_id(content_id, with_drafts: with_drafts)
      .translations[:available_translations]
  end

  subject(:translations_by_edition) do
    described_class
      .by_edition(edition)
      .translations[:available_translations]
  end

  let(:content_id) { link_set.content_id }
  let(:edition) { nil }

  def create_edition(base_path, state = "published", locale = "en", version = 1)
    create(
      :edition,
      document: Document.find_or_create_by(content_id: link_set.content_id, locale: locale),
      base_path: base_path,
      state: state,
      content_store: state == "draft" ? "draft" : "live",
      user_facing_version: version,
    )
  end

  let(:link_set) { create(:link_set) }

  context "with items in a matching state" do
    let(:with_drafts) { false }

    before do
      create_edition("/a", "published")
      create_edition("/a.ar", "published", "ar")
      create_edition("/a.es", "published", "es")
    end

    it "returns all the items" do
      expect(translations).to match_array([
        a_hash_including(base_path: "/a", locale: "en"),
        a_hash_including(base_path: "/a.ar", locale: "ar"),
        a_hash_including(base_path: "/a.es", locale: "es"),
      ])
    end
  end

  context "with withdrawn editions" do
    let(:with_drafts) { true }

    before do
      create_edition("/a", "published").unpublish(type: "withdrawal", explanation: "Withdrawn for a test.")
      create_edition("/a.ar", "published", "ar")
      create_edition("/a.es", "draft", "es")
    end

    it "returns all the items" do
      expect(translations).to match_array([
        a_hash_including(base_path: "/a", locale: "en"),
        a_hash_including(base_path: "/a.ar", locale: "ar"),
        a_hash_including(base_path: "/a.es", locale: "es"),
      ])
    end
  end

  context "when edition we're generating translations for is different in the database" do
    let(:with_drafts) { false }
    let(:database_edition) { create_edition("/a", "published") }

    before do
      create_edition("/a.fr", "published", "fr")
      Edition.where(id: database_edition.id).update_all(title: "A title")
    end

    it "has not updated the model" do
      expect(database_edition.title).to eq("VAT rates")
    end

    context "when passing the edition" do
      let(:edition) { database_edition }

      it "returns the data within the edition rather than the database" do
        expect(translations_by_edition).to match_array([
          a_hash_including(base_path: "/a", locale: "en", title: "VAT rates"),
          a_hash_including(base_path: "/a.fr", locale: "fr"),
        ])
      end
    end

    context "when passing the content_id" do
      let(:content_id) { database_edition.content_id }

      it "returns the data as is stored in the database" do
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en", title: "A title"),
          a_hash_including(base_path: "/a.fr", locale: "fr"),
        ])
      end
    end
  end

  context "with gone editions" do
    let(:with_drafts) { false }

    before do
      create_edition("/a", "published")
      create_edition("/a.ar", "published", "ar")
      create_edition("/a.es", "published", "es").unpublish(type: "gone", explanation: "Removed for a test.")
    end

    it "returns the items which are not gone" do
      expect(translations).to match_array([
        a_hash_including(base_path: "/a", locale: "en"),
        a_hash_including(base_path: "/a.ar", locale: "ar"),
      ])
    end
  end

  context "with items in more than one state" do
    let!(:en) { create_edition("/a", "published") }
    let!(:ar) { create_edition("/a.ar", "draft", "ar") }
    let!(:es) { create_edition("/a.es", "published", "es") }

    context "with drafts" do
      let(:with_drafts) { true }

      it "returns items in all states in the fallback order" do
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en"),
          a_hash_including(base_path: "/a.ar", locale: "ar"),
          a_hash_including(base_path: "/a.es", locale: "es"),
        ])
      end

      it "takes the item in the first matching state" do
        es.update_attribute("title", "no habla español")
        draft_es = create_edition("/a.es", "draft", "es", 2)
        draft_es.update_attribute("title", "mais on parle français")
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en"),
          a_hash_including(base_path: "/a.ar", locale: "ar"),
          a_hash_including(base_path: "/a.es", locale: "es", title: "mais on parle français"),
        ])
      end
    end

    context "without drafts" do
      let(:with_drafts) { false }

      it "does not return items with states not in the fallback order" do
        expect(translations).to match_array([
          a_hash_including(base_path: "/a", locale: "en"),
          a_hash_including(base_path: "/a.es", locale: "es"),
        ])
      end
    end
  end
end
