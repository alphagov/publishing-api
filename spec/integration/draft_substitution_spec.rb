require "rails_helper"

RSpec.describe "Substituting content that is not published" do
  let(:put_content_command) { Commands::V2::PutContent }

  let(:content_id) { SecureRandom.uuid }
  let(:another_content_id) { SecureRandom.uuid }

  let(:guide_payload) do
    {
      content_id: content_id,
      base_path: "/vat-rates",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "guide",
      locale: "en",
      routes: [{ path: "/vat-rates", type: "exact" }],
      redirects: [],
      phase: "beta",
    }
  end

  let(:gone_payload) do
    {
      content_id: another_content_id,
      base_path: "/vat-rates",
      format: "gone",
      publishing_app: "publisher",
      routes: [{ path: "/vat-rates", type: "exact" }],
    }
  end

  describe "after the first substitution" do
    before do
      put_content_command.call(guide_payload)
      put_content_command.call(gone_payload)
    end

    it "discards the guide" do
      expect(ContentItem.count).to eq(1)

      content_item = ContentItem.first
      state = State.find_by!(content_item: content_item)

      expect(content_item.document_type).to eq("gone")
      expect(state.name).to eq("draft")
    end

    describe "after the second substitution" do
      before do
        put_content_command.call(guide_payload)
      end

      it "discards the gone" do
        expect(ContentItem.count).to eq(1)

        content_item = ContentItem.first
        state = State.find_by!(content_item: content_item)

        expect(content_item.document_type).to eq("guide")
        expect(state.name).to eq("draft")
      end

      describe "after the third substitution" do
        before do
          put_content_command.call(gone_payload)
        end

        it "discards the guide" do
          expect(ContentItem.count).to eq(1)

          content_item = ContentItem.first
          state = State.find_by!(content_item: content_item)

          expect(content_item.document_type).to eq("gone")
          expect(state.name).to eq("draft")
        end
      end
    end
  end

  describe "putting a content item in a different locale" do
    before do
      put_content_command.call(guide_payload)
      put_content_command.call(gone_payload.merge(locale: "fr"))
    end

    it "does not discard the guide" do
      expect(ContentItem.count).to eq(2)

      guide_item = ContentItem.first
      gone_item = ContentItem.second

      guide_state = State.find_by!(content_item: guide_item)
      gone_state = State.find_by!(content_item: gone_item)

      expect(guide_state.name).to eq("draft")
      expect(gone_state.name).to eq("draft")
    end
  end
end
