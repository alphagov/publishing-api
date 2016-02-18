require "rails_helper"

RSpec.describe "Withdrawing Content Items" do
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
      links: {},
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

  describe "after the first withdrawl" do
    before do
      put_content_command.call(guide_payload)
      put_content_command.call(gone_payload)
    end

    it "withdraws the previous draft content item" do
      expect(ContentItem.count).to eq(2)

      withdrawn_item = ContentItem.first
      draft_item = ContentItem.second

      withdrawn = State.find_by!(content_item: withdrawn_item)
      draft = State.find_by!(content_item: draft_item)

      expect(withdrawn.name).to eq("withdrawn")
      expect(draft.name).to eq("draft")
    end

    describe "after the second withdrawl" do
      before do
        put_content_command.call(guide_payload)
      end

      it "withdraws the second draft content item" do
        expect(ContentItem.count).to eq(3)

        withdrawn1_item = ContentItem.first
        withdrawn2_item = ContentItem.second
        draft_item = ContentItem.third

        withdrawn1 = State.find_by!(content_item: withdrawn1_item)
        withdrawn2 = State.find_by!(content_item: withdrawn2_item)
        draft = State.find_by!(content_item: draft_item)

        expect(withdrawn1.name).to eq("withdrawn")
        expect(withdrawn2.name).to eq("withdrawn")
        expect(draft.name).to eq("draft")
      end
    end
  end
end
