require "rails_helper"

RSpec.describe Commands::V2::Import, type: :request do
  describe "#call" do
    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/bar" }

    let(:content_item) do
      {
        document_type: "foo1",
        schema_name: "generic",
        publishing_app: "foo",
        title: "foo",
        rendering_app: "foo",
        base_path: base_path,
        routes: [{ "path": "/bar", "type": "exact" }],
        details: {},
        locale: "en",
        state: "superseded",
      }
    end

    let(:payload) do
      {
        content_id: content_id,
        content_items: [
          {
            action: "PutContent",
            payload: content_item,
          },
          {
            action: "PutContent",
            payload: content_item.merge(
              title: "bar",
            ),
          },
          {
            action: "Publish",
            payload: content_item.merge(state: "published", update_type: "major"),
          },
        ]
      }
    end

    subject { described_class.call(payload) }

    it "creates the full content item history" do
      expect { subject }.to change { ContentItem.count }.by(3)
    end

    it "creates the full location history" do
      expect { subject }.to change { Location.count }.by(3)
    end

    it "creates the full Translation history" do
      expect { subject }.to change { Translation.count }.by(3)
    end

    it "creates the state history" do
      subject
      expect(State.all.map(&:name)).to match_array(%w(superseded superseded published))
    end

    it "creates the full User facing version history" do
      subject
      expect(UserFacingVersion.all.map(&:number)).to match_array([1, 2, 3])
    end

    it "creates the full Lock version history" do
      subject
      content_item_ids = ContentItem.where(content_id: content_id).map(&:id)
      expect(LockVersion.where(target_id: content_item_ids).map(&:number)).to match_array([1, 2, 3])
    end

    it "sends the last published item to the content_store" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
      subject
    end

    context "with an existing content item" do
      let!(:existing_content_item) { FactoryGirl.create(:content_item, content_id: content_id).id }

      it "deletes previous content items" do
        subject
        expect(ContentItem.where(id: existing_content_item)).to be_empty
      end

      it "deletes previous states" do
        subject
        expect(State.where(content_item_id: existing_content_item)).to be_empty
      end
    end
  end
end
