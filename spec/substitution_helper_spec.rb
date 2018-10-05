require "rails_helper"

RSpec.describe SubstitutionHelper do
  let(:existing_document_type) { "nonexistent-schema" }
  let(:new_document_type) { "nonexistent-schema" }
  let(:existing_base_path) { "/vat-rates" }

  let!(:existing_item) {
    create(:draft_edition,
      document_type: existing_document_type,
      base_path: existing_base_path)
  }

  before do
    stub_request(
      :delete,
      Plek.find("draft-content-store") + "/content#{existing_base_path}"
    )
  end

  context "given a base_path" do
    before do
      subject.clear!(
        new_item_document_type: new_document_type,
        new_item_content_id: new_content_id,
        base_path: existing_base_path,
        locale: "en",
        state: existing_item.state,
      )
    end

    context "when the content_id is the same as the existing item" do
      let(:new_content_id) { existing_item.document.content_id }

      it "does not discard the existing draft" do
        expect(Edition.exists?(id: existing_item.id)).to be true
      end

      context "when the existing item is published" do
        let!(:existing_item) {
          create(:live_edition,
            document_type: existing_document_type,
            base_path: existing_base_path)
        }

        it "does not unpublish the existing published item" do
          expect(existing_item.reload.substitute?).to be false
        end
      end
    end

    context "when the existing edition is unpublished" do
      let(:existing_item) do
        create(
          :gone_unpublished_edition,
          base_path: existing_base_path,
        )
      end

      let(:new_content_id) { SecureRandom.uuid }

      it "substitutes the draft" do
        expect(existing_item.reload.substitute?).to be true
      end
    end

    context "when the content_id differs from the existing item" do
      let(:new_content_id) { SecureRandom.uuid }

      context "when the existing item has a document_type that is substitutable" do
        let(:existing_document_type) { "gone" }

        it "discards the existing draft" do
          expect(Edition.exists?(id: existing_item.id)).to be false
        end

        it "doesn't unpublish any other items" do
          live_item = create(:live_edition,
            document_type: existing_document_type,
            base_path: existing_base_path)

          french_item = create(:draft_edition,
            document: create(:document, locale: "fr"),
            document_type: existing_document_type,
            base_path: existing_base_path)

          item_elsewhere = create(:draft_edition,
            document_type: existing_document_type,
            base_path: "/somewhere-else")

          expect(live_item.state).not_to eq("unpublished")
          expect(french_item.state).not_to eq("unpublished")
          expect(item_elsewhere.state).not_to eq("unpublished")
        end

        context "when the existing item is published" do
          let!(:existing_item) {
            create(:live_edition,
              document_type: existing_document_type,
              base_path: existing_base_path)
          }

          it "unpublishes the existing published item" do
            expect(existing_item.reload.substitute?).to be true
          end
        end
      end

      context "when the new item has a document_type that is substitutable" do
        let(:new_document_type) { "gone" }

        it "discards the existing draft" do
          expect(Edition.exists?(id: existing_item.id)).to be false
        end

        it "doesn't unpublish any other items" do
          live_item = create(:live_edition,
            document_type: existing_document_type,
            base_path: existing_base_path)

          french_item = create(:draft_edition,
            document: create(:document, locale: "fr"),
            document_type: existing_document_type,
            base_path: existing_base_path)

          item_elsewhere = create(:draft_edition,
            document_type: existing_document_type,
            base_path: "/somewhere-else")

          expect(live_item.state).not_to eq("unpublished")
          expect(french_item.state).not_to eq("unpublished")
          expect(item_elsewhere.state).not_to eq("unpublished")
        end

        context "when the existing item is published" do
          let!(:existing_item) {
            create(:live_edition,
              document_type: existing_document_type,
              base_path: existing_base_path)
          }

          it "unpublishes the existing published item" do
            expect(existing_item.reload.substitute?).to be true
          end
        end
      end

      context "when neither item has a document_type that is substitutable" do
        it "does not discard the existing draft" do
          expect(Edition.exists?(id: existing_item.id)).to be true
        end

        context "when the existing item is published" do
          let!(:existing_item) {
            create(:live_edition,
              document_type: existing_document_type,
              base_path: existing_base_path)
          }

          it "does not unpublish the existing item" do
            expect(existing_item.reload.substitute?).to be false
          end
        end
      end
    end
  end

  context "when base_path is nil" do
    it "raises an exception" do
      expect {
        subject.clear!(
          new_item_document_type: "government",
          new_item_content_id: SecureRandom.uuid,
          base_path: nil,
          locale: "en",
          state: "draft",
        )
      }.to raise_error(SubstitutionHelper::NilBasePathError)
    end
  end
end
