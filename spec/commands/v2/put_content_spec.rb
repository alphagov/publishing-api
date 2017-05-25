require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }
    let(:locale) { "en" }

    let(:change_note) { { note: "Info", public_timestamp: Time.now.utc.to_s } }

    let(:payload) do
      {
        content_id: content_id,
        base_path: base_path,
        update_type: "major",
        title: "Some Title",
        publishing_app: "publisher",
        rendering_app: "frontend",
        document_type: "nonexistent-schema",
        schema_name: "nonexistent-schema",
        locale: locale,
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
        change_note: change_note
      }
    end

    it "validates the payload" do
      validator = double(:validator)
      expect(Commands::V2::PutContentValidator).to receive(:new)
        .with(payload, instance_of(described_class))
        .and_return(validator)
      expect(validator).to receive(:validate)
      expect(PathReservation).to receive(:reserve_base_path!)
      expect{ described_class.call(payload) }.not_to raise_error
    end


    it "sends to the downstream draft worker" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          a_hash_including(:content_id, :locale, :payload_version, update_dependencies: true),
        )

      described_class.call(payload)
    end

    it "does not send to the downstream publish worker" do
      expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)
      described_class.call(payload)
    end

    it "creates an action" do
      expect(Action.count).to be 0
      described_class.call(payload)
      expect(Action.count).to be 1
      expect(Action.first.attributes).to match a_hash_including(
        "content_id" => content_id,
        "locale" => locale,
        "action" => "PutContent",
      )
    end

    context "when the 'downstream' parameter is false" do
      it "does not send to the downstream draft worker" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)

        described_class.call(payload, downstream: false)
      end
    end

    context "when the 'bulk_publishing' flag is set" do
      it "enqueues in the correct queue" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(
            "downstream_low",
            anything
          )

        described_class.call(payload.merge(bulk_publishing: true))
      end
    end

    context "when there are no previous path reservations" do
      it "creates a path reservation" do
        expect {
          described_class.call(payload)
        }.to change(PathReservation, :count).by(1)

        reservation = PathReservation.last
        expect(reservation.base_path).to eq("/vat-rates")
        expect(reservation.publishing_app).to eq("publisher")
      end
    end

    context "when the base path has been reserved by another publishing app" do
      before do
        FactoryGirl.create(:path_reservation,
          base_path: base_path,
          publishing_app: "something-else"
        )
      end

      it "raises an error" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, /is already reserved/i)
      end
    end

    context "when creating a draft for a previously published edition" do
      let(:first_published_at) { 1.year.ago }

      let(:document) do
        FactoryGirl.create(
          :document,
          content_id: content_id,
          stale_lock_version: 5,
        )
      end

      let!(:edition) do
        FactoryGirl.create(:live_edition,
          document: document,
          user_facing_version: 5,
          first_published_at: first_published_at,
          base_path: base_path,
        )
      end

      let!(:link) do
        edition.links.create(link_type: "test",
                             target_content_id: document.content_id)
      end

      it "creates the draft's user-facing version using the live's user-facing version as a starting point" do
        described_class.call(payload)

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.user_facing_version).to eq(6)
      end

      it "copies over the first_published_at timestamp" do
        described_class.call(payload)

        edition = Edition.last
        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)

        expect(edition.first_published_at.iso8601).to eq(first_published_at.iso8601)
      end

      context "and the base path has changed" do
        before do
          payload.merge!(
            base_path: "/moved",
            routes: [{ path: "/moved", type: "exact" }],
          )
        end

        it "sets the correct base path on the location" do
          described_class.call(payload)

          expect(Edition.where(base_path: "/moved", state: "draft")).to exist
        end

        it "creates a redirect" do
          described_class.call(payload)

          redirect = Edition.find_by(
            base_path: base_path,
            state: "draft",
          )

          expect(redirect).to be_present
          expect(redirect.schema_name).to eq("redirect")
          expect(redirect.publishing_app).to eq("publisher")

          expect(redirect.redirects).to eq([{
            path: base_path,
            type: "exact",
            destination: "/moved",
          }])
        end

        it "sends a create request to the draft content store for the redirect" do
          expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).twice

          described_class.call(payload)
        end

        context "when the locale differs from the existing draft edition" do
          before do
            payload.merge!(locale: "fr", title: "French Title")
          end

          it "creates a separate draft edition in the given locale" do
            described_class.call(payload)
            expect(Edition.count).to eq(2)

            edition = Edition.last
            expect(edition.title).to eq("French Title")
            expect(edition.document.locale).to eq("fr")
          end
        end
      end

      describe "race conditions", skip_cleaning: true do
        after do
          DatabaseCleaner.clean_with :truncation
        end

        it "copes with race conditions" do
          described_class.call(payload)
          Commands::V2::Publish.call(content_id: content_id, update_type: "minor")

          thread1 = Thread.new { described_class.call(payload) }
          thread2 = Thread.new { described_class.call(payload) }
          thread1.join
          thread2.join

          expect(Edition.all.pluck(:state)).to match_array(%w(superseded published draft))
        end
      end
    end

    context "when creating a draft for a previously unpublished edition" do
      before do
        FactoryGirl.create(:unpublished_edition,
          document: FactoryGirl.create(:document, content_id: content_id, stale_lock_version: 2),
          user_facing_version: 5,
          base_path: base_path,
        )
      end

      it "creates the draft's lock version using the unpublished lock version as a starting point" do
        described_class.call(payload)

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.document.stale_lock_version).to eq(3)
      end

      it "creates the draft's user-facing version using the unpublished user-facing version as a starting point" do
        described_class.call(payload)

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.state).to eq("draft")
        expect(edition.user_facing_version).to eq(6)
      end

      it "allows the setting of first_published_at" do
        explicit_first_published = DateTime.new(2016, 05, 23, 1, 1, 1).rfc3339
        payload[:first_published_at] = explicit_first_published

        described_class.call(payload)

        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.first_published_at).to eq(explicit_first_published)
      end
    end

    context "when the payload is for a brand new edition" do
      it "creates an edition" do
        described_class.call(payload)
        edition = Edition.last

        expect(edition).to be_present
        expect(edition.document.content_id).to eq(content_id)
        expect(edition.title).to eq("Some Title")
      end

      it "sets a draft state for the edition" do
        described_class.call(payload)
        edition = Edition.last

        expect(edition.state).to eq("draft")
      end

      it "sets a user-facing version of 1 for the edition" do
        described_class.call(payload)
        edition = Edition.last

        expect(edition.user_facing_version).to eq(1)
      end

      it "creates a lock version for the edition" do
        described_class.call(payload)
        edition = Edition.last

        expect(edition.document.stale_lock_version).to eq(1)
      end

      shared_examples "creates a change note" do
        it "creates a change note" do
          expect { described_class.call(payload) }.
            to change { ChangeNote.count }.by(1)
        end
      end

      context "and the change node is in the payload" do
        include_examples "creates a change note"
      end

      context "and the change history is in the details hash" do
        before do
          payload.delete(:change_note)
          payload[:details] = { change_history: [change_note] }
        end

        include_examples "creates a change note"
      end

      context "and the change note is in the details hash" do
        before do
          payload.delete(:change_note)
          payload[:details] = { change_note: change_note[:note] }
        end

        include_examples "creates a change note"
      end
    end

    context "when the params includes an access limit" do
      before do
        payload.merge!(access_limited: { users: ["new-user"] })
      end

      it "creates a new access limit" do
        expect {
          described_class.call(payload)
        }.to change(AccessLimit, :count).by(1)

        access_limit = AccessLimit.last
        expect(access_limit.users).to eq(["new-user"])
        expect(access_limit.edition).to eq(Edition.last)
      end
    end

    it_behaves_like TransactionalCommand

    context "when the draft does not exist" do
      context "with a provided last_edited_at" do
        it "stores the provided timestamp" do
          last_edited_at = 1.year.ago

          described_class.call(payload.merge(last_edited_at: last_edited_at))

          edition = Edition.last

          expect(edition.last_edited_at.iso8601).to eq(last_edited_at.iso8601)
        end
      end

      it "stores last_edited_at as the current time" do
        Timecop.freeze do
          described_class.call(payload)

          edition = Edition.last

          expect(edition.last_edited_at.iso8601).to eq(Time.zone.now.iso8601)
        end
      end
    end

    context "when the draft does exist" do
      let!(:edition) do
        FactoryGirl.create(:draft_edition,
          document: FactoryGirl.create(:document, content_id: content_id)
        )
      end

      context "with a provided last_edited_at" do
        %w(minor major republish).each do |update_type|
          context "with update_type of #{update_type}" do
            it "stores the provided timestamp" do
              last_edited_at = 1.year.ago

              described_class.call(
                payload.merge(
                  update_type: update_type,
                  last_edited_at: last_edited_at,
                )
              )

              edition.reload

              expect(edition.last_edited_at.iso8601).to eq(last_edited_at.iso8601)
            end
          end
        end
      end

      it "stores last_edited_at as the current time" do
        Timecop.freeze do
          described_class.call(payload)

          edition.reload

          expect(edition.last_edited_at.iso8601).to eq(Time.zone.now.iso8601)
        end
      end

      context "when other update type" do
        it "dosen't change last_edited_at" do
          old_last_edited_at = edition.last_edited_at

          described_class.call(payload.merge(update_type: "republish"))

          edition.reload

          expect(edition.last_edited_at).to eq(old_last_edited_at)
        end
      end
    end

    context "field doesn't change between drafts" do
      it "doesn't update the dependencies" do
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(anything, a_hash_including(update_dependencies: true))
        expect(DownstreamDraftWorker).to receive(:perform_async_in_queue)
          .with(anything, a_hash_including(update_dependencies: false))
        described_class.call(payload)
        described_class.call(payload)
      end
    end

    context "when the update_type is 'republish'" do
      before { payload[:update_type] = "republish" }

      context "and there is a previous edition" do
        let(:document) do
          FactoryGirl.create(:document, content_id: content_id)
        end

        let!(:previous_edition) do
          FactoryGirl.create(:live_edition,
            document: document,
            base_path: base_path,
            last_edited_at: Time.zone.now
          )
        end

        it "uses the last_edited_at value from the previous edition" do
          described_class.call(payload)
          edition = Edition.last
          expect(edition.last_edited_at.iso8601).to eq previous_edition.last_edited_at.iso8601
        end
      end

      context "but there is not a previous edition" do
        it "has a last_edited_at of nil" do
          described_class.call(payload)
          edition = Edition.last
          expect(edition.last_edited_at).to be_nil
        end
      end
    end
  end
end
