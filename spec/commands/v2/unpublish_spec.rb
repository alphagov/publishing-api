require "rails_helper"

RSpec.describe Commands::V2::Unpublish do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }
  let(:locale) { "en" }
  let(:document) do
    FactoryGirl.create(:document,
      content_id: content_id,
      locale: locale,
    )
  end

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
      let!(:live_edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          base_path: base_path,
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

      it "raises an error when explanation is blank" do
        msg = "Validation failed: Explanation can't be blank"
        expect { described_class.call(payload) }
          .to raise_error(CommandError, msg) do |error|
            expect(error.code).to eq(422)
          end
      end

      it "raises an error when redirected without alternative_path" do
        msg = /Validation failed: Redirects destination must be present/
        expect { described_class.call(payload.merge(type: "redirect", alternative_path: "")) }
          .to raise_error(CommandError, msg) do |error|
            expect(error.code).to eq(422)
          end
      end
    end

    context "when passing redirects" do
      let!(:live_edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          base_path: base_path,
        )
      end

      let(:payload) do
        {
          content_id: content_id,
          type: "redirect",
          alternative_path: alternative_path,
          redirects: redirects,
        }
      end

      context "with an alternative_path" do
        let(:redirects) { nil }
        let(:alternative_path) { "/something-great" }

        it "should populate the redirects hash" do
          described_class.call(payload)

          unpublishing = Unpublishing.first
          expect(unpublishing.redirects).to match_array([
            a_hash_including(destination: "/something-great")
          ])
        end
      end

      context "with a redirects hash" do
        let(:alternative_path) { nil }
        let(:redirects) do
          [
            {
              path: base_path,
              type: :exact,
              destination: "/something-amazing",
            }
          ]
        end

        it "should populate the redirects hash" do
          described_class.call(payload)

          unpublishing = Unpublishing.first
          expect(unpublishing.redirects).to match_array([
            a_hash_including(destination: "/something-amazing")
          ])
        end

        context "including a destination with a fragment" do
          let(:redirects) do
            [
              {
                path: base_path,
                type: :prefix,
                destination: "/something-amazing#foo",
              }
            ]
          end

          it "should populate the redirects hash" do
            described_class.call(payload)

            unpublishing = Unpublishing.first
            expect(unpublishing.redirects).to match_array([
              a_hash_including(destination: "/something-amazing#foo")
            ])
          end
        end
      end
    end

    context "when the document is published" do
      let!(:live_edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          base_path: base_path,
        )
      end

      include_examples "creates an action"

      it "sets the edition's state to `unpublished`" do
        described_class.call(payload)

        expect(live_edition.reload.state).to eq("unpublished")
      end

      it "creates an Unpublishing" do
        described_class.call(payload)

        unpublishing = Unpublishing.find_by(edition: live_edition)
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
          }.to raise_error(CommandError, "Could not find an edition to unpublish") { |error|
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

          unpublishing = Unpublishing.find_by(edition: live_edition)
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

            unpublishing = Unpublishing.find_by(edition: live_edition)
            expect(unpublishing.unpublished_at).to eq DateTime.new(2016, 8, 1, 10, 10, 10)
          end
        end
      end
    end

    context "when only a draft is present" do
      let!(:draft_edition) do
        FactoryGirl.create(:draft_edition,
          document: document,
          user_facing_version: 3,
        )
      end

      it "rejects the request with a 404" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "Could not find an edition to unpublish") { |error|
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

        it "sets the edition's state to `unpublished`" do
          described_class.call(payload_with_allow_draft)

          expect(draft_edition.reload.state).to eq("unpublished")
        end

        it "creates an Unpublishing" do
          described_class.call(payload_with_allow_draft)

          unpublishing = Unpublishing.find_by(edition: draft_edition)
          expect(unpublishing.type).to eq("gone")
          expect(unpublishing.explanation).to eq("Removed for testing porpoises")
          expect(unpublishing.alternative_path).to eq("/new-path")
        end

        context "where there is an access limit" do
          before do
            AccessLimit.create!(
              edition: draft_edition,
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

        context "when there is a previously unpublished edition" do
          let!(:previous_edition) do
            FactoryGirl.create(:unpublished_edition,
              document: document,
              base_path: base_path,
              user_facing_version: 1,
            )
          end
          let(:french_document) do
            FactoryGirl.create(:document,
              content_id: document.content_id,
              locale: "fr",
            )
          end

          it "supersedes the unpublished item" do
            described_class.call(payload.merge(allow_draft: true))

            expect(previous_edition.reload.state).to eq("superseded")
          end

          it "does not supersede unpublished items in a different locale" do
            Edition.find_by!(id: previous_edition.id)
              .update(document: french_document)

            described_class.call(payload.merge(allow_draft: true))

            expect(previous_edition.reload.state).to eq("unpublished")
          end
        end

        context "when there is a previously published edition" do
          let!(:previous_edition) do
            FactoryGirl.create(:live_edition,
              document: document,
              base_path: base_path,
              user_facing_version: 1,
            )
          end
          let(:french_document) do
            FactoryGirl.create(:document,
              content_id: document.content_id,
              locale: "fr",
            )
          end

          it "supersedes the published item" do
            described_class.call(payload.merge(allow_draft: true))

            expect(previous_edition.reload.state).to eq("superseded")
          end

          it "does not supersede published items in a different locale" do
            Edition.find_by!(id: previous_edition.id)
              .update(document: french_document)

            described_class.call(payload.merge(allow_draft: true))

            expect(previous_edition.reload.state).to eq("published")
          end
        end
      end
    end

    context "when there is a draft and published with differing links" do
      let(:link_a) { SecureRandom.uuid }
      let(:link_b) { SecureRandom.uuid }
      let!(:draft_edition) do
        FactoryGirl.create(:draft_edition,
          document: document,
          user_facing_version: 2,
          links_hash: { topics: [link_b] },
        )
      end

      let!(:live_edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          links_hash: { topics: [link_a] },
        )
      end

      after do
        described_class.call(payload.merge(allow_draft: true))
      end

      it "includes orphaned content ids downstream live" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue)
          .with("downstream_high", a_hash_including(orphaned_content_ids: [link_a]))
      end

      it "excludes orphaned content ids downstream draft as they were handled in put content" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with("downstream_high", hash_excluding(:orphaned_content_ids))
      end
    end

    context "when the document is redrafted" do
      let!(:live_edition) do
        FactoryGirl.create(:live_edition,
          :with_draft,
          document: document,
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

          editions = Edition.with_document.where("documents.content_id": content_id)

          expect(editions.count).to eq(1)
          expect(editions.last.state).to eq("unpublished")
        end

        it "unpublishes the edition" do
          described_class.call(payload)
          live_edition.reload

          unpublishing = Unpublishing.find_by(edition: live_edition)
          expect(unpublishing).not_to be_nil
        end
      end
    end

    context "when the document is already unpublished" do
      let!(:unpublished_edition) do
        FactoryGirl.create(:unpublished_edition,
          document: document,
          base_path: base_path,
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
        expect(unpublished_edition.reload.state).to eq("unpublished")
      end

      it "updates the Unpublishing" do
        unpublishing = Unpublishing.find_by(edition: unpublished_edition)
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
        let!(:unpublished_edition) do
          FactoryGirl.create(:substitute_unpublished_edition,
            document: document,
          )
        end

        it "rejects the request with a 404" do
          message = "Could not find an edition to unpublish"
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
        FactoryGirl.create(:live_edition, :with_draft, document: document)
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
      let!(:live_edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          base_path: nil,
        )
      end

      include_examples "creates an action"

      it "sets the edition's state to `unpublished`" do
        described_class.call(payload)

        expect(live_edition.reload.state).to eq("unpublished")
      end

      it "creates an Unpublishing" do
        described_class.call(payload)

        unpublishing = Unpublishing.find_by(edition: live_edition)
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
