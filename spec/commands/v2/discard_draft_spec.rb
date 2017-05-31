require "rails_helper"

RSpec.describe Commands::V2::DiscardDraft do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:expected_content_store_payload) { { base_path: "/vat-rates" } }
    let(:locale) { "en" }
    let(:document) do
      FactoryGirl.create(:document,
        locale: "en",
        stale_lock_version: stale_lock_version,
      )
    end
    let(:stale_lock_version) { 1 }
    let(:base_path) { "/vat-rates" }
    let(:payload) { { content_id: document.content_id } }

    before do
      allow_any_instance_of(Presenters::EditionPresenter)
        .to receive(:for_content_store)
        .and_return(expected_content_store_payload)
    end

    context "when a draft edition exists for the given content_id" do
      let(:user_facing_version) { 2 }
      let!(:existing_draft_item) do
        FactoryGirl.create(:access_limited_draft_edition,
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

      context "creates an action" do
        let(:content_id) { document.content_id }
        let(:action_payload) { payload }
        let(:action) { "DiscardDraft" }
        include_examples "creates an action"
      end

      it "deletes the supporting objects for the draft item" do
        described_class.call(payload)

        access_limit = AccessLimit.find_by(edition: existing_draft_item)
        change_notes = ChangeNote.where(edition: existing_draft_item)

        expect(access_limit).to be_nil
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

      context "a published edition exists with the same base_path" do
        let(:stale_lock_version) { 3 }
        let!(:published_item) do
          FactoryGirl.create(:live_edition,
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

          access_limit = AccessLimit.find_by(edition: existing_draft_item)
          expect(access_limit).to be_nil
        end

        it "deletes the draft" do
          expect {
            described_class.call(payload)
          }.to change(Edition, :count).by(-1)
        end
      end

      context "a published edition exists with a different base_path" do
        let!(:published_item) do
          FactoryGirl.create(:live_edition,
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

      context "an unpublished edition exits" do
        let(:unpublished_item) do
          FactoryGirl.create(:unpublished_edition,
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
          FactoryGirl.create(:draft_edition,
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

          expect(Edition.where(id: french_draft_item.id)).not_to exist
        end

        it "does not delete the english edition" do
          described_class.call(payload)
          expect(Edition.where(id: existing_draft_item.id)).to exist
        end
      end

      it_behaves_like TransactionalCommand
    end

    context "when no draft edition exists for the given content_id" do
      it "raises a command error with code 404" do
        expect { described_class.call(payload) }.to raise_error(CommandError) do |error|
          expect(error.code).to eq(404)
        end
      end

      context "and a published edition exists" do
        before do
          FactoryGirl.create(:live_edition, document: document)
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
