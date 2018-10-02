require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  describe "call" do
    before do
      stub_request(:delete, %r{.*content-store.*/content/.*})
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:content_id) { SecureRandom.uuid }
    let(:new_content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }
    let(:locale) { "en" }

    let(:change_note) { "Info" }
    let(:new_change_note) { "Changed Info" }
    let(:payload) do
      {
        content_id: content_id,
        base_path: base_path,
        update_type: "major",
        title: "Some Title",
        publishing_app: "publisher",
        rendering_app: "frontend",
        document_type: "services_and_information",
        schema_name: "generic",
        locale: locale,
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
        change_note: change_note,
        details: {},
      }
    end

    let(:updated_payload) do
      {
        content_id: content_id,
        base_path: base_path,
        update_type: "major",
        title: "New Title",
        publishing_app: "publisher",
        rendering_app: "frontend",
        document_type: "services_and_information",
        schema_name: "generic",
        locale: locale,
        routes: [{ path: base_path, type: "exact" }],
        redirects: [],
        phase: "beta",
        change_note: new_change_note,
        details: {},
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
          a_hash_including(:content_id, :locale, update_dependencies: true),
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
      described_class.call(updated_payload)
      expect(Action.last.attributes).to match a_hash_including(
        "content_id" => content_id,
        "locale" => locale,
        "action" => "PutContent",
      )

      expect(Action.last.edition_diff).to include(
        ["~", [:title], "Some Title", "New Title"],
        ["~", [:change_note], change_note.to_s, new_change_note.to_s],
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

          described_class.call(payload.merge(last_edited_at: last_edited_at.iso8601))

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
        create(:draft_edition,
          document: create(:document, content_id: content_id))
      end

      context "with a provided last_edited_at" do
        %w(minor major republish).each do |update_type|
          context "with update_type of #{update_type}" do
            it "stores the provided timestamp" do
              last_edited_at = 1.year.ago

              described_class.call(
                payload.merge(
                  update_type: update_type,
                  last_edited_at: last_edited_at.iso8601,
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

    context "when no update_type is provided" do
      before do
        payload.delete(:update_type)
      end

      it "should send an alert to GovukError" do
        expect(GovukError).to receive(:notify)
          .with(anything, level: "warning", extra: a_hash_including(content_id: content_id))

        described_class.call(payload)
      end
    end

    context "when an update type is provided" do
      it "should not send an alert to GovukError" do
        expect(GovukError).to_not receive(:notify)
          .with(anything, level: "warning", extra: a_hash_including(content_id: content_id))

        described_class.call(payload)
      end
    end
  end
end
