require "rails_helper"

RSpec.describe Commands::V2::Publish do
  describe "call" do
    let(:draft_item) { FactoryGirl.create(:draft_content_item, content_id: content_id) }
    let(:content_id) { SecureRandom.uuid }

    before do
      FactoryGirl.create(:version, target: draft_item, number: 2)
    end

    around do |example|
      Timecop.freeze { example.run }
    end

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

      context "with no public_updated_at in the payload" do
        before do
          stub_request(:put, %r{.*content-store.*/content/.*})
        end

        context "for a major update" do
          it "updates the public_updated_at time" do
            described_class.call(payload)

            expect(LiveContentItem.last.public_updated_at).to be_within(1.second).of(Time.zone.now)
          end
        end

        context "for a minor update" do
          let!(:another_content_id) { SecureRandom.uuid }
          let!(:live_item) do
            FactoryGirl.create(:live_content_item, :with_draft, content_id: another_content_id, base_path: "/hat-rates")
          end

          let!(:payload) do
            {
              content_id: another_content_id,
              update_type: "minor",
            }
          end

          before do
            FactoryGirl.create(:version, target: live_item.draft_content_item, number: 2)
          end

          it "preserves the public_updated_at value from the last live item" do
            described_class.call(payload)

            expect(LiveContentItem.last.public_updated_at).to eq(live_item.public_updated_at)
          end
        end
      end

      context "with public_updated_at in the payload" do
        before do
          stub_request(:put, %r{.*content-store.*/content/.*})
        end

        let(:public_updated_at) { Time.zone.now.iso8601 }

        let(:payload) do
          {
            content_id: content_id,
            previous_version: 2,
            public_updated_at: public_updated_at
          }
        end

        context "for a major update" do
          it "uses the public_updated_at time" do
            payload[:update_type] = "major"

            described_class.call(payload)

            expect(LiveContentItem.last.public_updated_at.iso8601).to eq(public_updated_at)
          end
        end

        context "for a minor update" do
          it "uses the public_updated_at time" do
            payload[:update_type] = "major"

            described_class.call(payload)

            expect(LiveContentItem.last.public_updated_at.iso8601).to eq(public_updated_at)
          end
        end
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
