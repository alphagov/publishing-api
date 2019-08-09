require "rails_helper"

RSpec.describe Queries::LiveEditionBlockingDraftEdition do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id: content_id) }
  let(:base_path) { "/vat-rates" }
  let(:document_type) { "nonexistent-schema" }

  describe ".call" do
    subject { described_class.call(content_id, base_path, document_type) }

    shared_examples "check succeeds" do
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "with a single edition" do
      before do
        create(:draft_edition,
               document: document,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      include_examples "check succeeds"
    end

    context "with two editions of different locales" do
      before do
        create(:draft_edition,
               document: document,
               base_path: base_path + ".en",
               document_type: document_type,
               user_facing_version: 1)

        create(:draft_edition,
               document: create(:document, content_id: document.content_id, locale: "es"),
               base_path: base_path + ".es",
               document_type: document_type,
               user_facing_version: 1)
      end

      include_examples "check succeeds"
    end

    context "with a unpublished item, of type \"substitute\", and a draft at the same base path" do
      before do
        create(:substitute_unpublished_edition,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)

        create(:draft_edition,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      include_examples "check succeeds"
    end

    context "with a published item, with a substitutable document_type, and a draft at the same base path" do
      before do
        create(:live_edition,
               base_path: base_path,
               document_type: "unpublishing",
               user_facing_version: 1)

        create(:draft_edition,
               document: document,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      include_examples "check succeeds"
    end

    context "with a draft with a substitutable document_type, and a published item at the same base path" do
      let(:document_type) { "unpublishing" }

      before do
        create(:live_edition,
               base_path: base_path,
               document_type: "nonexistent-schema",
               user_facing_version: 1)

        create(:draft_edition,
               document: document,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      include_examples "check succeeds"
    end

    context "with a unpublished item, and a draft at the same base path" do
      before do
        @blocking_edition = create(:gone_unpublished_edition,
                                   base_path: base_path,
                                   document_type: document_type,
                                   user_facing_version: 1)

        create(:edition,
               document: document,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      it "fails, returning the id of the edition" do
        expect(subject).to eq(@blocking_edition.id)
      end
    end

    context "with a published item, and a draft at the same base path" do
      before do
        @blocking_edition = create(:live_edition,
                                   base_path: base_path,
                                   document_type: document_type,
                                   user_facing_version: 1)

        create(:draft_edition,
               document: document,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      it "fails, returning the id of the edition" do
        expect(subject).to eq(@blocking_edition.id)
      end
    end

    context "with no base_path" do
      let(:base_path) { nil }

      let!(:blocking_edition) do
        create(:live_edition,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      let!(:blocking_edition_2) do
        create(:live_edition,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      let!(:content) do
        create(:draft_edition,
               document: document,
               base_path: base_path,
               document_type: document_type,
               user_facing_version: 1)
      end

      it "doesn't raise any errors" do
        expect { subject }.to_not raise_error
      end
    end
  end
end
