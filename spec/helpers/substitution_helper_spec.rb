require "rails_helper"

RSpec.describe SubstitutionHelper do
  let(:existing_format) { "guide" }
  let(:new_format) { "guide" }
  let(:existing_base_path) { "/vat-rates" }

  let!(:existing_item) {
    create(:draft_content_item,
      format: existing_format,
      base_path: existing_base_path,
    )
  }

  let!(:live_item) {
    create(:live_content_item,
      format: existing_format,
      base_path: existing_base_path,
    )
  }
  let!(:french_item) {
    create(:draft_content_item,
      format: existing_format,
      base_path: existing_base_path,
      locale: "fr",
    )
  }
  let!(:item_elsewhere) {
    create(:draft_content_item,
      format: existing_format,
      base_path: "/somewhere-else",
    )
  }


  before do
    subject.clear!(
      new_item_format: new_format,
      new_item_content_id: new_content_id,
      base_path: existing_base_path,
      locale: "en",
      state: "draft",
    )
  end

  context "when the content_id is the same as the existing item" do
    let(:new_content_id) { existing_item.content_id }

    it "does not unpublish the existing item" do
      state = State.find_by!(content_item: existing_item)
      expect(state.name).not_to eq("unpublished")
    end
  end

  context "when the content_id differs from the existing item" do
    let(:new_content_id) { SecureRandom.uuid }

    context "when the existing item has a format that is substitutable" do
      let(:existing_format) { "gone" }

      it "unpublishes the existing item" do
        state = State.find_by!(content_item: existing_item)
        expect(state.name).to eq("unpublished")
      end

      it "doesn't unpublish any other items" do
        expect(State.find_by!(content_item: live_item).name).not_to eq("unpublished")
        expect(State.find_by!(content_item: french_item).name).not_to eq("unpublished")
        expect(State.find_by!(content_item: item_elsewhere).name).not_to eq("unpublished")
      end
    end

    context "when the new item has a format that is substitutable" do
      let(:new_format) { "gone" }

      it "unpublishes the existing item" do
        state = State.find_by!(content_item: existing_item)
        expect(state.name).to eq("unpublished")
      end

      it "doesn't unpublish any other items" do
        expect(State.find_by!(content_item: live_item).name).not_to eq("unpublished")
        expect(State.find_by!(content_item: french_item).name).not_to eq("unpublished")
        expect(State.find_by!(content_item: item_elsewhere).name).not_to eq("unpublished")
      end
    end

    context "when neither item has a format that is substitutable" do
      it "does not unpublish the existing item" do
        state = State.find_by!(content_item: existing_item)
        expect(state.name).not_to eq("unpublished")
      end
    end
  end
end
