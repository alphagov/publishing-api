require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  include IntegrationSpecHelper

  describe "call" do
    let(:payload) { default_payload }

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
  end
end
