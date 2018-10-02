require "rails_helper"

RSpec.describe Queries::GetLinkables do
  let(:document_type) { "contact" }

  describe "#call" do
    before { Rails.cache.clear }

    subject(:linkables) { described_class.new(document_type: document_type).call }

    context "when there is a single edition" do
      let(:base_path) { "/path" }
      let(:content_id) { SecureRandom.uuid }
      let(:internal_name) { "Internal Name" }
      let(:title) { "Title" }
      before do
        create(:live_edition,
          base_path: base_path,
          details: { internal_name: internal_name },
          document: create(:document, content_id: content_id),
          document_type: document_type,
          title: title)
      end

      it "returns an array of linkable presenters" do
        expect(linkables).to match_array([
          an_instance_of(Queries::LinkablePresenter)
        ])
      end

      it "returns the expected linkable" do
        expect(linkables.first.to_h).to eq(
          base_path: base_path,
          content_id: content_id,
          internal_name: internal_name,
          publication_state: "published",
          title: title,
        )
      end

      context "and there isn't an internal name given" do
        let(:internal_name) { nil }

        it "returns title instead of internal_name" do
          expect(linkables.first.to_h).to match(
            a_hash_including(internal_name: title)
          )
        end
      end
    end

    context "when there are a number of editions matching a document_type" do
      let!(:editions) do
        3.times.map { create(:live_edition, document_type: document_type) }
      end
      let(:edition_content_ids) { editions.map { |e| e.document.content_id } }

      it "returns an array of LinkablePresenter" do
        expect(linkables).to match_array([
          an_instance_of(Queries::LinkablePresenter),
          an_instance_of(Queries::LinkablePresenter),
          an_instance_of(Queries::LinkablePresenter),
        ])
      end

      it "returns the editions" do
        expect(linkables.map(&:content_id)).to match_array(edition_content_ids)
      end
    end

    context "when there is a an edition with a placeholder of the document_type" do
      let!(:editions) do
        [
          create(:live_edition, document_type: "contact"),
          create(:live_edition, document_type: "placeholder_contact"),
        ]
      end
      let(:edition_content_ids) { editions.map { |e| e.document.content_id } }

      it "returns both linkables" do
        expect(linkables.length).to be(2)
      end

      it "returns the editions" do
        expect(linkables.map(&:content_id)).to match_array(edition_content_ids)
      end
    end

    context "when there is a an edition with a different document_type" do
      before do
        create(:live_edition, document_type: "different")
      end

      it { is_expected.to be_empty }
    end

    context "when the edition is not available in English" do
      before do
        create(:live_edition,
          document_type: document_type,
          document: create(:document, locale: "fr"))
      end

      it { is_expected.to be_empty }
    end

    context "when the edition is available in English and French" do
      let(:content_id) { SecureRandom.uuid }
      before do
        create(:live_edition,
          document_type: document_type,
          title: "Hello",
          document: create(:document, content_id: content_id))
        create(:live_edition,
          document_type: document_type,
          title: "Salut",
          document: create(:document, content_id: content_id, locale: "fr"))
      end

      it "has the english title" do
        expect(linkables.map(&:title)).to match_array(["Hello"])
      end
    end

    context "when the edition is available in draft" do
      let(:document) { create(:document) }
      let!(:draft_edition) do
        create(:draft_edition,
          document_type: document_type,
          title: "Draft",
          document: document,
          user_facing_version: 2)
      end

      it "has the draft edition" do
        expect(linkables.map(&:title)).to match_array(["Draft"])
      end

      context "and there is a published edition" do
        let!(:published_edition) do
          create(:live_edition,
            document_type: document_type,
            title: "Published",
            document: document)
        end

        it "has the published edition" do
          expect(linkables.map(&:title)).to match_array(["Published"])
        end
      end
    end

    context "when an edition is unpublished" do
      before do
        create(:unpublished_edition, document_type: document_type)
      end

      it { is_expected.to be_empty }
    end

    context "when an edition is superseded" do
      before do
        create(:superseded_edition, document_type: document_type)
      end

      it { is_expected.to be_empty }
    end
  end
end
