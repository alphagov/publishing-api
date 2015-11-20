require "rails_helper"

RSpec.describe Commands::V2::Publish do
  describe "call" do
    before do
      previous = FactoryGirl.create(:draft_content_item, content_id: content_id)
      FactoryGirl.create(:version, target: previous, number: 2)
    end

    let(:content_id) { SecureRandom.uuid }
    let(:payload) do
      {
        content_id: content_id,
        update_type: "major",
        previous_version: 2
      }
    end

    context "with no update_type" do
      let(:payload) { { content_id: content_id } }

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /update_type is required/)
      end
    end


    context "with a stale version" do

      let(:payload) do
        {
          content_id: content_id,
          update_type: "major",
          previous_version: 3
        }
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /Conflict/)
      end
    end

    context "with a valid payload" do
      it "creates or replaces a live content item" do
        stub_request(:put, %r{.*content-store.*/content/.*})
        expect {
          described_class.call(payload)
        }.to change(LiveContentItem, :count).by(1)
      end

      it "sends a payload downstream asynchronously" do
        presentation = {
          content_id: content_id,
          transmitted_at: Time.now.to_s(:nanoseconds),
          title: "Something something"
        }.to_json
        allow(Presenters::ContentStorePresenter)
          .to receive(:present)
          .and_return(presentation)

        expect(ContentStoreWorker)
          .to receive(:perform_async)
          .with(content_store: Adapters::ContentStore,
               base_path: "/vat-rates",
               payload: presentation)

        described_class.call(payload)
      end
    end
  end
end
