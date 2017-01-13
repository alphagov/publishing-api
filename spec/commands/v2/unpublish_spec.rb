require "rails_helper"

RSpec.describe Commands::V2::Unpublish do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let(:locale) { "en" }

  describe "call" do
    let(:payload) do
      {
        content_id: content_id,
        type: "gone",
        explanation: "Removed for testing porpoises",
        alternative_path: "/new-path",
      }
    end
    let(:action_payload) { payload }
    let(:action) { "UnpublishGone" }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when unpublishing is invalid" do
      let!(:live_content_item) do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
          locale: locale,
        )
      end

      let(:payload) do
        {
          content_id: content_id,
          type: "withdrawal",
          explanation: nil,
          alternative_path: "/new-path",
        }
      end

      it "raises an error when expanation is blank" do
        msg = "Validation failed: Explanation can't be blank"
        expect { described_class.call(payload) }
          .to raise_error(CommandError, msg) do |error|
            expect(error.code).to eq(422)
          end
      end

      it "raises an error when redirected without alternative_path" do
        msg = "Validation failed: Alternative path can't be blank"
        expect { described_class.call(payload.merge(type: "redirect", alternative_path: '')) }
          .to raise_error(CommandError, msg) do |error|
            expect(error.code).to eq(422)
          end
      end
    end

    shared_examples "creates an action" do
      it "creates an action" do
        expect(Action.count).to be 0
        described_class.call(action_payload)
        expect(Action.count).to be 1
        expect(Action.first.attributes).to match a_hash_including(
          "content_id" => content_id,
          "locale" => locale,
          "action" => action,
        )
      end
    end

    context "when the document is published" do
      let!(:live_content_item) do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
          locale: locale,
        )
      end

      include_examples "creates an action"

      it "sets the content item's state to `unpublished`" do
        described_class.call(payload)

        expect(live_content_item.reload.state).to eq("unpublished")
      end

      it "creates an Unpublishing" do
        described_class.call(payload)

        unpublishing = Unpublishing.find_by(content_item: live_content_item)
        expect(unpublishing.type).to eq("gone")
        expect(unpublishing.explanation).to eq("Removed for testing porpoises")
        expect(unpublishing.alternative_path).to eq("/new-path")
      end

      it "sends an unpublishing downstream" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(content_id: content_id, locale: locale)
          )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(content_id: content_id, locale: locale)
          )

        described_class.call(payload)
      end

      context "and the allow_draft parameter is given" do
        let(:payload_with_allow_draft) do
          payload.merge(
            allow_draft: true,
          )
        end

        it "rejects the request with a 404" do
          expect {
            described_class.call(payload_with_allow_draft)
          }.to raise_error(CommandError, "Could not find a content item to unpublish") { |error|
            expect(error.code).to eq(404)
          }
        end
      end

      context "and the unpublished_at parameter is set" do
        let(:payload) do
          {
            content_id: content_id,
            type: "gone",
            explanation: "Removed for testing porpoises",
            alternative_path: "/new-path",
            unpublished_at: DateTime.new(2016, 8, 1, 1, 1, 1).rfc3339
          }
        end

        it "ignores the provided unpublished_at" do
          described_class.call(payload)

          unpublishing = Unpublishing.find_by(content_item: live_content_item)
          expect(unpublishing.unpublished_at).to be_nil
        end

        context "for a withdrawal" do
          let(:payload) do
            {
              content_id: content_id,
              type: "withdrawal",
              explanation: "Removed for testing porpoises",
              alternative_path: "/new-path",
              unpublished_at: DateTime.new(2016, 8, 1, 10, 10, 10).rfc3339
            }
          end

          it "persists the provided unpublished_at" do
            described_class.call(payload)

            unpublishing = Unpublishing.find_by(content_item: live_content_item)
            expect(unpublishing.unpublished_at).to eq DateTime.new(2016, 8, 1, 10, 10, 10)
          end
        end
      end
    end

    context "when only a draft is present" do
      let!(:draft_content_item) do
        FactoryGirl.create(
          :draft_content_item,
          content_id: content_id,
          user_facing_version: 3,
          locale: locale,
        )
      end

      it "rejects the request with a 404" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "Could not find a content item to unpublish") { |error|
          expect(error.code).to eq(404)
        }
      end

      context "and the allow_draft parameter is given" do
        let(:payload_with_allow_draft) do
          payload.merge(
            allow_draft: true,
          )
        end

        let(:action_payload) { payload_with_allow_draft }
        include_examples "creates an action"

        it "sets the content item's state to `unpublished`" do
          described_class.call(payload_with_allow_draft)

          expect(draft_content_item.reload.state).to eq("unpublished")
        end

        it "creates an Unpublishing" do
          described_class.call(payload_with_allow_draft)

          unpublishing = Unpublishing.find_by(content_item: draft_content_item)
          expect(unpublishing.type).to eq("gone")
          expect(unpublishing.explanation).to eq("Removed for testing porpoises")
          expect(unpublishing.alternative_path).to eq("/new-path")
        end

        context "where there is an access limit" do
          before do
            AccessLimit.create!(
              content_item: draft_content_item,
              users: [SecureRandom.uuid]
            )
          end

          it "removes the access limit model" do
            expect {
              described_class.call(payload_with_allow_draft)
            }.to change(AccessLimit, :count).by(-1)
          end
        end

        it "sends an unpublishing to the live content store" do
          expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
            .with(
              "downstream_high",
              a_hash_including(content_id: content_id, locale: locale)
            )

          described_class.call(payload_with_allow_draft)
        end

        context "with `discard_drafts` set to true" do
          let(:payload_with_allow_draft_and_discard_drafts) do
            payload_with_allow_draft.merge(
              discard_drafts: true,
            )
          end

          it "rejects the request with a 422" do
            expected_message = "allow_draft and discard_drafts cannot be used together"
            expect {
              described_class.call(payload_with_allow_draft_and_discard_drafts)
            }.to raise_error(CommandError, expected_message) { |error|
              expect(error.code).to eq(422)
            }
          end
        end

        context "when there is a previously unpublished content item" do
          let!(:previous_content_item) do
            FactoryGirl.create(:unpublished_content_item,
              content_id: content_id,
              base_path: base_path,
              user_facing_version: 1,
            )
          end

          it "supersedes the unpublished item" do
            described_class.call(payload.merge(allow_draft: true))

            expect(previous_content_item.reload.state).to eq("superseded")
          end

          it "does not supersede unpublished items in a different locale" do
            t = ContentItem.find_by!(id: previous_content_item.id)
            t.update!(locale: "fr")

            described_class.call(payload.merge(allow_draft: true))

            expect(previous_content_item.reload.state).to eq("unpublished")
          end
        end

        context "when there is a previously published content item" do
          let!(:previous_content_item) do
            FactoryGirl.create(:live_content_item,
              content_id: content_id,
              base_path: base_path,
              locale: locale,
              user_facing_version: 1,
            )
          end

          it "supersedes the published item" do
            described_class.call(payload.merge(allow_draft: true))

            expect(previous_content_item.reload.state).to eq("superseded")
          end

          it "does not supersede published items in a different locale" do
            t = ContentItem.find_by!(id: previous_content_item.id)
            t.update!(locale: "fr")

            described_class.call(payload.merge(allow_draft: true))

            expect(previous_content_item.reload.state).to eq("published")
          end
        end
      end
    end

    context "when the document is redrafted" do
      let!(:live_content_item) do
        FactoryGirl.create(
          :live_content_item,
          :with_draft,
          content_id: content_id,
          locale: locale,
        )
      end

      it "rejects the request with a 422" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "Cannot unpublish with a draft present") { |error|
          expect(error.code).to eq(422)
        }
      end

      context "with `discard_drafts` set to true" do
        let(:payload) do
          {
            content_id: content_id,
            type: "gone",
            discard_drafts: true,
          }
        end

        before do
          stub_request(:delete, %r{.*content-store.*/content/.*})
        end

        it "discards the draft" do
          described_class.call(payload)

          content_items = ContentItem.where(content_id: content_id)
          expect(content_items.count).to eq(1)

          expect(content_items.last.state).to eq("unpublished")
        end

        it "unpublishes the content item" do
          described_class.call(payload)
          live_content_item.reload

          unpublishing = Unpublishing.find_by(content_item: live_content_item)
          expect(unpublishing).not_to be_nil
        end
      end
    end

    context "when the document is already unpublished" do
      let!(:unpublished_content_item) do
        FactoryGirl.create(:unpublished_content_item,
          content_id: content_id,
          base_path: base_path,
          locale: locale,
          explanation: "This explnatin has a typo",
          alternative_path: "/new-path",
        )
      end

      let(:payload) do
        {
          content_id: content_id,
          type: "gone",
          explanation: "This explanation is correct",
        }
      end

      include_examples "creates an action"

      it "maintains the state of unpublished" do
        described_class.call(payload)
        expect(unpublished_content_item.reload.state).to eq("unpublished")
      end

      it "updates the Unpublishing" do
        unpublishing = Unpublishing.find_by(content_item: unpublished_content_item)
        expect(unpublishing.explanation).to eq("This explnatin has a typo")

        described_class.call(payload)

        unpublishing.reload

        expect(unpublishing.explanation).to eq("This explanation is correct")
        expect(unpublishing.alternative_path).to be_nil
      end

      it "sends an unpublishing to the draft content store" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(content_id: content_id)
          )

        described_class.call(payload)
      end

      it "sends an unpublishing to the draft content store" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(content_id: content_id)
          )

        described_class.call(payload)
      end

      it "sends an unpublishing to the live content store" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_high",
            a_hash_including(content_id: content_id)
          )

        described_class.call(payload)
      end

      context "when the unpublishing type is substitute" do
        let!(:unpublished_content_item) do
          FactoryGirl.create(:substitute_unpublished_content_item,
            content_id: content_id,
            locale: locale,
          )
        end

        it "rejects the request with a 404" do
          message = "Could not find a content item to unpublish"
          expect {
            described_class.call(payload)
          }.to raise_error(CommandError, message) { |error|
            expect(error.code).to eq(404)
          }
        end
      end
    end

    context "with the `downstream` flag set to `false`" do
      before do
        FactoryGirl.create(:live_content_item, :with_draft,
          content_id: content_id,
          locale: locale,
        )
      end

      it "does not send to any downstream system for a 'gone'" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)

        redraft_payload = payload.merge(
          type: "gone",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end

      it "does not send to any downstream system for a 'redirect'" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)

        redraft_payload = payload.merge(
          type: "redirect",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end

      it "does not send to any downstream system for a 'withdrawal'" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)

        redraft_payload = payload.merge(
          type: "withdrawal",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end

      it "does not send to any downstream system for 'vanish'" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)

        redraft_payload = payload.merge(
          type: "withdrawal",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end
    end

    context "when the document has no location" do
      let!(:live_content_item) do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          locale: locale,
          base_path: nil,
        )
      end

      include_examples "creates an action"

      it "sets the content item's state to `unpublished`" do
        described_class.call(payload)

        expect(live_content_item.reload.state).to eq("unpublished")
      end

      it "creates an Unpublishing" do
        described_class.call(payload)

        unpublishing = Unpublishing.find_by(content_item: live_content_item)
        expect(unpublishing.type).to eq("gone")
        expect(unpublishing.explanation).to eq("Removed for testing porpoises")
        expect(unpublishing.alternative_path).to eq("/new-path")
      end

      it "does not send to any content store" do
        expect(DownstreamService).not_to receive(:update_live_content_store)
        expect(DownstreamService).not_to receive(:update_draft_content_store)

        described_class.call(payload)
      end
    end
  end
end
