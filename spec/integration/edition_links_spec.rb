require "rails_helper"

RSpec.describe "Edition Links" do
  let(:content_a) { SecureRandom.uuid }
  let(:content_b) { SecureRandom.uuid }

  let!(:document_a_en) { FactoryGirl.create(:document, content_id: content_a) }
  let!(:document_b_en) { FactoryGirl.create(:document, content_id: content_b) }
  let!(:document_a_fr) { FactoryGirl.create(:document, content_id: content_a, locale: "fr") }
  let!(:document_b_fr) { FactoryGirl.create(:document, content_id: content_b, locale: "fr") }

  let(:locale) { "en" }
  let(:with_drafts) { false }

  subject(:expanded_links) do
    LinkExpansion.new(
      content_id,
      with_drafts: with_drafts,
      locale: locale,
    ).links_with_content
  end

  context "direct links" do
    let(:content_id) { content_a }
    let!(:live_edition_a_en) { FactoryGirl.create(:live_edition, document: document_a_en, base_path: "/a.en") }
    let!(:live_edition_b_en) { FactoryGirl.create(:live_edition, document: document_b_en, base_path: "/b.en") }
    let!(:draft_edition_a_en) { FactoryGirl.create(:draft_edition, document: document_a_en, base_path: "/a.en", user_facing_version: 2) }

    before do
      live_edition_a_en.links.create(link_type: "test", target_content_id: content_b)
    end

    context "without drafts" do
      it "should have a link to B" do
        expect(expanded_links[:test]).to match([a_hash_including(base_path: "/b.en")])
      end
    end

    context "with drafts" do
      let(:with_drafts) { true }

      it "should not have a link" do
        expect(expanded_links).to be_empty
      end

      it "should fallback to live with links" do
        draft_edition_a_en.delete
        expect(expanded_links[:test]).to match([a_hash_including(base_path: "/b.en")])
      end
    end

    context "with french translation of A" do
      let!(:live_edition_a_fr) { FactoryGirl.create(:live_edition, document: document_a_fr, base_path: "/a.fr") }
      let(:locale) { "fr" }

      it "should not have a link" do
        expect(expanded_links).to be_empty
      end
    end

    context "with french translation of B" do
      let!(:live_edition_b_fr) { FactoryGirl.create(:live_edition, document: document_b_fr, base_path: "/b.fr") }
      let(:locale) { "en" }

      it "should not have a link" do
        expect(expanded_links[:test]).to match([a_hash_including(base_path: "/b.en")])
      end
    end
  end

  context "reverse links" do
    let(:content_id) { content_a }
    let!(:edition_a_en) { FactoryGirl.create(:live_edition, document: document_a_en, base_path: "/a.en") }
    let!(:edition_b_en) { FactoryGirl.create(:live_edition, document: document_b_en, base_path: "/b.en") }
    let!(:edition_a_fr) { FactoryGirl.create(:live_edition, document: document_a_fr, base_path: "/a.fr") }
    let!(:draft_edition_a_fr) { FactoryGirl.create(:draft_edition, document: document_a_fr, base_path: "/a.fr", user_facing_version: 2) }
    let!(:edition_b_fr) { FactoryGirl.create(:live_edition, document: document_b_fr, base_path: "/b.fr") }
    let!(:draft_edition_b_fr) { FactoryGirl.create(:draft_edition, document: document_b_fr, base_path: "/b.fr", user_facing_version: 2) }
    let(:locale) { "fr" }

    before do
      edition_a_fr.links.create(link_type: "documents", target_content_id: content_b)
    end

    context "with drafts" do
      let(:with_drafts) { true }

      context "from A" do
        it "should not have links" do
          expect(expanded_links[:document_collections]).to_not be
        end
      end

      context "from B" do
        let(:content_id) { content_b }

        it "should not have reverse links" do
          expect(expanded_links[:document_collections]).to_not be
        end
      end
    end

    context "without drafts" do
      let(:with_drafts) { false }

      context "from A" do
        it "should have a link to B" do
          expect(expanded_links[:documents]).to match([a_hash_including(base_path: "/b.fr")])
        end
      end

      context "from B" do
        let(:content_id) { content_b }

        it "should have a reverse link to A" do
          expect(expanded_links[:document_collections]).to match([a_hash_including(base_path: "/a.fr")])
        end
      end
    end

    context "English translation" do
      let(:locale) { "en" }

      context "from A" do
        it "should not have any links" do
          expect(expanded_links[:documents]).to be_nil
        end
      end

      context "from B" do
        let(:content_id) { content_b }

        it "should not have any reverse links" do
          expect(expanded_links[:document_collections]).to_not be
        end
      end
    end
  end

  context "recursive direct links" do
    let(:content_id) { content_a }
    let!(:edition_a_en) { FactoryGirl.create(:live_edition, document: document_a_en, base_path: "/a.en") }
    let!(:edition_b_en) { FactoryGirl.create(:live_edition, document: document_b_en, base_path: "/b.en") }
    let(:locale) { "en" }

    before do
      edition_a_en.links.create(link_type: "parent_taxons", target_content_id: content_b)
    end

    context "from A" do
      let(:content_id) { content_a }
      it "should have a link to B" do
        expect(expanded_links[:parent_taxons]).to match([a_hash_including(base_path: "/b.en")])
      end
    end

    context "from B" do
      let(:content_id) { content_b }
      it "should have a reverse link to A" do
        expect(expanded_links[:child_taxons]).to match([a_hash_including(base_path: "/a.en")])
      end
    end

    context "with a link to itself" do
      before do
        edition_a_en.links.create(link_type: "parent_taxons", target_content_id: content_a)
      end

      context "from A" do
        it "should have a link to A and B" do
          expect(expanded_links[:child_taxons]).to match([a_hash_including(base_path: "/a.en")])
          expect(expanded_links[:parent_taxons]).to match([a_hash_including(base_path: "/b.en")])
        end
      end

      context "from B" do
        let(:content_id) { content_b }
        it "should have a reverse link to A and B" do
          expect(expanded_links[:child_taxons]).to match([a_hash_including(
            base_path: "/a.en",
            links: {
              parent_taxons: [a_hash_including({ base_path: "/b.en" })]
            }
          )])
        end
      end
    end
  end
end
