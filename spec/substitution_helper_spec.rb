require "rails_helper"

RSpec.describe SubstitutionHelper do
  let(:existing_document_type) { "guide" }
  let(:new_document_type) { "guide" }
  let(:existing_base_path) { "/vat-rates" }

  let!(:existing_item) {
    FactoryGirl.create(:draft_content_item,
      document_type: existing_document_type,
      base_path: existing_base_path,
    )
  }

  before do
    stub_request(
      :delete,
      Plek.find('draft-content-store') + "/content#{existing_base_path}"
    )
  end

  context "given a base_path" do
    before do
      subject.clear!(
        new_item_document_type: new_document_type,
        new_item_content_id: new_content_id,
        base_path: existing_base_path,
        locale: "en",
        state: State.find_by!(content_item: existing_item).name,
      )
    end

    context "when the content_id is the same as the existing item" do
      let(:new_content_id) { existing_item.content_id }

      it "does not discard the existing draft" do
        expect(ContentItem.exists?(id: existing_item.id)).to eq(true)
      end

      context "when the existing item is published" do
        let!(:existing_item) {
          FactoryGirl.create(:live_content_item,
            document_type: existing_document_type,
            base_path: existing_base_path,
          )
        }

        it "does not unpublish the existing published item" do
          state = State.find_by!(content_item: existing_item)
          expect(state.name).not_to eq("unpublished")
        end
      end
    end

    context "when the content_id differs from the existing item" do
      let(:new_content_id) { SecureRandom.uuid }

      context "when the existing item has a document_type that is substitutable" do
        let(:existing_document_type) { "gone" }

        it "discards the existing draft" do
          expect(ContentItem.exists?(id: existing_item.id)).to eq(false)
        end

        it "doesn't unpublish any other items" do
          live_item = FactoryGirl.create(:live_content_item,
            document_type: existing_document_type,
            base_path: existing_base_path,
          )

          french_item = FactoryGirl.create(:draft_content_item,
            document_type: existing_document_type,
            base_path: existing_base_path,
            locale: "fr",
          )

          item_elsewhere = FactoryGirl.create(:draft_content_item,
            document_type: existing_document_type,
            base_path: "/somewhere-else",
          )

          expect(State.find_by!(content_item: live_item).name).not_to eq("unpublished")
          expect(State.find_by!(content_item: french_item).name).not_to eq("unpublished")
          expect(State.find_by!(content_item: item_elsewhere).name).not_to eq("unpublished")
        end

        context "when the existing item is published" do
          let!(:existing_item) {
            FactoryGirl.create(:live_content_item,
              document_type: existing_document_type,
              base_path: existing_base_path,
            )
          }

          it "unpublishes the existing published item" do
            state = State.find_by!(content_item: existing_item)
            expect(state.name).to eq("unpublished")
          end
        end
      end

      context "when the new item has a document_type that is substitutable" do
        let(:new_document_type) { "gone" }

        it "discards the existing draft" do
          expect(ContentItem.exists?(id: existing_item.id)).to eq(false)
        end

        it "doesn't unpublish any other items" do
          live_item = FactoryGirl.create(:live_content_item,
            document_type: existing_document_type,
            base_path: existing_base_path,
          )

          french_item = FactoryGirl.create(:draft_content_item,
            document_type: existing_document_type,
            base_path: existing_base_path,
            locale: "fr",
          )

          item_elsewhere = FactoryGirl.create(:draft_content_item,
            document_type: existing_document_type,
            base_path: "/somewhere-else",
          )

          expect(State.find_by!(content_item: live_item).name).not_to eq("unpublished")
          expect(State.find_by!(content_item: french_item).name).not_to eq("unpublished")
          expect(State.find_by!(content_item: item_elsewhere).name).not_to eq("unpublished")
        end

        context "when the existing item is published" do
          let!(:existing_item) {
            FactoryGirl.create(:live_content_item,
              document_type: existing_document_type,
              base_path: existing_base_path,
            )
          }

          it "unpublishes the existing published item" do
            state = State.find_by!(content_item: existing_item)
            expect(state.name).to eq("unpublished")
          end
        end
      end

      context "when neither item has a document_type that is substitutable" do
        it "does not discard the existing draft" do
          expect(ContentItem.exists?(id: existing_item.id)).to eq(true)
        end

        context "when the existing item is published" do
          let!(:existing_item) {
            FactoryGirl.create(:live_content_item,
              document_type: existing_document_type,
              base_path: existing_base_path,
            )
          }

          it "does not unpublish the existing item" do
            state = State.find_by!(content_item: existing_item)
            expect(state.name).not_to eq("unpublished")
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
