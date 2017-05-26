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
      expect { described_class.call(payload) }.not_to raise_error
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
