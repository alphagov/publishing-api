require "rails_helper"

RSpec.describe Commands::V2::DiscardDraft do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
    let(:document) do
      FactoryGirl.create(:document,
        content_id: SecureRandom.uuid,
        locale: "en",
        stale_lock_version: stale_lock_version,
      )
    end
    let(:stale_lock_version) { 1 }
    let(:base_path) { "/vat-rates" }
    let(:payload) { { content_id: document.content_id } }

    before do
      allow(Presenters::ContentStorePresenter).to receive(:present)
        .and_return(expected_content_store_payload)
    end

    context "when a draft content item exists for the given content_id" do
      let(:user_facing_version) { 2 }
      let!(:existing_draft_item) do
        FactoryGirl.create(:access_limited_draft_content_item,
          document: document,
          base_path: base_path,
          user_facing_version: user_facing_version,
        )
      end
      let!(:change_note) { ChangeNote.create(edition: existing_draft_item) }

      it "deletes the draft item" do
        expect {
          described_class.call(payload)
        }.to change(Edition, :count).by(-1)

        expect(Edition.exists?(id: existing_draft_item.id)).to eq(false)
      end

      it "creates an action" do
        expect(Action.count).to be 0
        described_class.call(payload)
        expect(Action.count).to be 1
        expect(Action.first.attributes).to match a_hash_including(
          "content_id" => document.content_id,
          "locale" => document.locale,
          "action" => "DiscardDraft",
          "content_item_id" => existing_draft_item.id,
        )
      end

      it "deletes the supporting objects for the draft item" do
        described_class.call(payload)

        state = State.find_by(content_item: existing_draft_item)
        translation = Translation.find_by(content_item: existing_draft_item)
        location = Location.find_by(edition: existing_draft_item)
        access_limit = AccessLimit.find_by(edition: existing_draft_item)
        user_facing_version = UserFacingVersion.find_by(edition: existing_draft_item)
        lock_version = LockVersion.find_by(target: existing_draft_item)
        change_notes = ChangeNote.where(edition: existing_draft_item)

        expect(state).to be_nil
        expect(translation).to be_nil
        expect(location).to be_nil
        expect(access_limit).to be_nil
        expect(user_facing_version).to be_nil
        expect(lock_version).to be_nil
        expect(change_notes).to be_empty
      end

      it "deletes the draft item from the draft content store" do
        expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(
              base_path: base_path,
              content_id: document.content_id,
              locale: document.locale,
            ),
          )

        described_class.call(payload)
      end

      it "does not send any request to the live content store" do
        expect(DownstreamLiveWorker).not_to receive(:perform_async)

        described_class.call(payload)
      end

      it "does not send any messages on the message queue" do
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)
        described_class.call(payload)
      end

      context "when the draft's lock version differs from the given lock version" do
        before do
          payload[:previous_version] = document.stale_lock_version - 1
        end

        it "raises an error" do
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, /Conflict/)
        end
      end

      context "a published content item exists with the same base_path" do
        let(:stale_lock_version) { 3 }
        let!(:published_item) do
          FactoryGirl.create(:live_content_item,
            document: document,
            base_path: base_path,
            user_facing_version: user_facing_version - 1,
          )
        end

        it "increments the lock version of the published item" do
          expect {
            described_class.call(payload)
          }.to change { document.reload.stale_lock_version }.to(4)
        end

        it "it uses the downstream discard draft worker" do
          expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
            .with(
              DownstreamDiscardDraftWorker::HIGH_QUEUE,
              a_hash_including(
                base_path: base_path,
                content_id: document.content_id,
                locale: document.locale,
              ),
            )
          described_class.call(payload)
        end

        it "deletes the supporting objects for the draft item" do
          described_class.call(payload)

          state = State.find_by(content_item: existing_draft_item)
          translation = Translation.find_by(content_item: existing_draft_item)
          location = Location.find_by(edition: existing_draft_item)
          access_limit = AccessLimit.find_by(edition: existing_draft_item)
          user_facing_version = UserFacingVersion.find_by(edition: existing_draft_item)
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
          }.to change(Edition, :count).by(-1)
        end
      end

      context "a published content item exists with a different base_path" do
        let!(:published_item) do
          FactoryGirl.create(:live_content_item,
            document: document,
            base_path: "/hat-rates",
            user_facing_version: user_facing_version - 1,
          )
        end

        it "it uses downstream discard draft worker" do
          expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
            .with(
              DownstreamDiscardDraftWorker::HIGH_QUEUE,
              a_hash_including(
                base_path: base_path,
                content_id: document.content_id,
                locale: document.locale,
              ),
            )
          described_class.call(payload)
        end
      end

      context "an unpublished content item exits" do
        let(:unpublished_item) do
          FactoryGirl.create(:unpublished_content_item,
            document: document,
            base_path: base_path,
            user_facing_version: user_facing_version - 1,
          )
        end

        it "it uses downstream discard draft worker" do
          expect(DownstreamDiscardDraftWorker).to receive(:perform_async_in_queue)
            .with(
              DownstreamDiscardDraftWorker::HIGH_QUEUE,
              a_hash_including(
                base_path: base_path,
                content_id: document.content_id,
                locale: document.locale,
              ),
            )
          described_class.call(payload)
        end
      end

      context "when a locale is provided in the payload" do
        let(:french_document) do
          FactoryGirl.create(:document, content_id: document.content_id, locale: "fr")
        end
        let!(:french_draft_item) do
          FactoryGirl.create(:draft_content_item,
            document: french_document,
            base_path: "#{base_path}.fr",
          )
        end

        before do
          payload.merge!(locale: "fr")
        end

        it "deletes the draft for the given locale" do
          expect {
            described_class.call(payload)
          }.to change(Edition, :count).by(-1)

          expect(Edition.exists?(id: french_draft_item.id)).to eq(false),
                                                               "The French draft item was not removed"
        end

        it "does not delete the english content item" do
          described_class.call(payload)
          expect(Edition.exists?(id: existing_draft_item.id)).to eq(true),
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
          FactoryGirl.create(:live_content_item, document: document)
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
