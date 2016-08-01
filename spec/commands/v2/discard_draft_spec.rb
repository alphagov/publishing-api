require "rails_helper"

RSpec.describe Commands::V2::DiscardDraft do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }
    let(:payload) { { content_id: content_id } }

    before do
      allow(Presenters::ContentStorePresenter).to receive(:present)
        .and_return(expected_content_store_payload)
    end

    context "when a draft content item exists for the given content_id" do
      let!(:existing_draft_item) {
        FactoryGirl.create(:access_limited_draft_content_item,
          content_id: content_id,
          base_path: base_path,
          lock_version: 5,
        )
      }

      before do
        FactoryGirl.create(:linkable,
          content_item: existing_draft_item,
          base_path: base_path,
        )
      end

      it "deletes the draft item" do
        expect {
          described_class.call(payload)
        }.to change(ContentItem, :count).by(-1)

        expect(ContentItem.exists?(id: existing_draft_item.id)).to eq(false)
      end

      it "deletes the supporting objects for the draft item" do
        described_class.call(payload)

        state = State.find_by(content_item: existing_draft_item)
        translation = Translation.find_by(content_item: existing_draft_item)
        location = Location.find_by(content_item: existing_draft_item)
        access_limit = AccessLimit.find_by(content_item: existing_draft_item)
        user_facing_version = UserFacingVersion.find_by(content_item: existing_draft_item)
        lock_version = LockVersion.find_by(target: existing_draft_item)

        expect(state).to be_nil
        expect(translation).to be_nil
        expect(location).to be_nil
        expect(access_limit).to be_nil
        expect(user_facing_version).to be_nil
        expect(lock_version).to be_nil
      end

      it "deletes the linkable" do
        described_class.call(payload)

        linkable = Linkable.find_by(base_path: base_path)
        expect(linkable).to be_nil
      end

      it "deletes the draft item from the draft content store" do
        expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(base_path: base_path, content_id: content_id),
          )

        described_class.call(payload)
      end

      it "does not send any request to the live content store" do
        expect(PresentedContentStoreWorker).not_to receive(:perform_async)
          .with(content_store: Adapters::ContentStore)

        described_class.call(payload)
      end

      it "does not send any messages on the message queue" do
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
        described_class.call(payload)
      end

      context "when the draft's lock version differs from the given lock version" do
        before do
          lock_version = LockVersion.find_by!(target: existing_draft_item)
          payload[:previous_version] = lock_version.number - 1
        end

        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /Conflict/)
        end
      end

      context "a published content item exists with the same base_path" do
        let!(:published_item) {
          FactoryGirl.create(:live_content_item,
            content_id: content_id,
            lock_version: 3,
            base_path: base_path,
          )
        }

        it "increments the lock version of the published item" do
          published_lock_version = LockVersion.find_by!(target: published_item)

          expect {
            described_class.call(payload)
          }.to change { published_lock_version.reload.number }.to(4)
        end

        it "it uses the downstream discard draft worker" do
          expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
            .with(
              DownstreamDiscardDraftWorker::HIGH_QUEUE,
              a_hash_including(
                base_path: base_path,
                content_id: content_id,
                live_content_item_id: published_item.id,
              ),
            )
          described_class.call(payload)
        end

        it "deletes the supporting objects for the draft item" do
          described_class.call(payload)

          state = State.find_by(content_item: existing_draft_item)
          translation = Translation.find_by(content_item: existing_draft_item)
          location = Location.find_by(content_item: existing_draft_item)
          access_limit = AccessLimit.find_by(content_item: existing_draft_item)
          user_facing_version = UserFacingVersion.find_by(content_item: existing_draft_item)
          lock_version = LockVersion.find_by(target: existing_draft_item)

          expect(state).to be_nil
          expect(translation).to be_nil
          expect(location).to be_nil
          expect(access_limit).to be_nil
          expect(user_facing_version).to be_nil
          expect(lock_version).to be_nil
        end

        it "deletes the draft" do
          expect {
            described_class.call(payload)
          }.to change(ContentItem, :count).by(-1)
        end
      end

      context "a published content item exists with a different base_path" do
        let!(:published_item) {
          FactoryGirl.create(:live_content_item,
            content_id: content_id,
            lock_version: 3,
            base_path: "/hat-rates",
          )
        }

        before do
          FactoryGirl.create(:linkable,
            content_item: published_item,
            base_path: "/hat-rates",
          )
        end

        it "it uses downstream discard draft worker" do
          expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
            .with(
              DownstreamDiscardDraftWorker::HIGH_QUEUE,
              a_hash_including(
                base_path: base_path,
                content_id: content_id,
                live_content_item_id: published_item.id,
              ),
            )
          described_class.call(payload)
        end

        it "does not delete the published linkable" do
          described_class.call(payload)

          linkable = Linkable.find_by(base_path: "/hat-rates")
          expect(linkable).not_to be_nil
          expect(linkable.content_item).to eq(published_item)
        end
      end

      context "an unpublished content item exits" do
        let(:unpublished_item) {
          FactoryGirl.create(:unpublished_content_item,
            base_path: base_path,
            content_id: content_id,
          )
        }

        it "it uses downstream discard draft worker" do
          expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
            .with(
              DownstreamDiscardDraftWorker::HIGH_QUEUE,
              a_hash_including(
                base_path: base_path,
                content_id: content_id,
                live_content_item_id: unpublished_item.id,
              ),
            )
          described_class.call(payload)
        end
      end

      context "when a locale is provided in the payload" do
        let!(:french_draft_item) {
          FactoryGirl.create(:draft_content_item,
            content_id: content_id,
            base_path: "#{base_path}.fr",
            locale: "fr",
          )
        }

        before do
          payload.merge!(locale: "fr")
        end

        it "deletes the draft for the given locale" do
          expect {
            described_class.call(payload)
          }.to change(ContentItem, :count).by(-1)

          expect(ContentItem.exists?(id: french_draft_item.id)).to eq(false),
            "The French draft item was not removed"
        end

        it "does not delete the english content item" do
          described_class.call(payload)
          expect(ContentItem.exists?(id: existing_draft_item.id)).to eq(true),
            "The English draft item was removed"
        end
      end

      it_behaves_like TransactionalCommand
    end

    context "when no draft content item exists for the given content_id" do
      it "raises a command error with code 404" do
        expect { described_class.call(payload) }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
        end
      end

      context "and a published content item exists" do
        before do
          FactoryGirl.create(:live_content_item, content_id: content_id)
        end

        it "raises a command error with code 422" do
          expect { described_class.call(payload) }.to raise_error(CommandError) do |error|
            expect(error.code).to eq(422)
          end
        end
      end
    end
  end
end
