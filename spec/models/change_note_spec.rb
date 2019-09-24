require "rails_helper"

RSpec.describe ChangeNote do
  let(:payload) { { change_note: payload_change_note } }
  let(:details) { {} }
  let(:payload_change_note) { nil }
  let(:update_type) { "major" }
  let(:edition) do
    create(:edition,
           update_type: update_type,
           details: details,
           public_updated_at: Time.zone.yesterday,
           change_note: nil)
  end

  describe ".create_from_edition" do
    subject { described_class.create_from_edition(payload, edition) }

    context "update_type is not major" do
      let(:update_type) { "minor" }
      it "doesn't create a change note" do
        expect { subject }.to_not change { ChangeNote.count }
      end
    end

    context "payload contains top-level change note entry" do
      let(:payload_change_note) { "Excellent" }
      it "populates change note from top-level change note entry" do
        Timecop.freeze do
          expect { subject }.to change { ChangeNote.count }.by(1)
          result = ChangeNote.last
          expect(result.note).to eq "Excellent"
          expect(result.public_timestamp.iso8601).to eq Time.zone.now.iso8601
        end
      end

      context "change note is entered for an existing edition" do
        it "updates the change note rather than creating a new one" do
          subject
          expect {
            described_class.create_from_edition(payload, edition)
          }.to_not change { ChangeNote.count }
        end
      end

      context "payload contains public_updated_at" do
        it "sets the change note public_timestamp to public_updated_at time" do
          time = Time.zone.yesterday
          payload[:public_updated_at] = time
          described_class.create_from_edition(payload, edition)

          expect(ChangeNote.last.public_timestamp).to eq(time)
        end
      end
    end

    context "edition has change_note entry in details hash" do
      let(:details) { { change_note: "Marvellous" }.stringify_keys }
      it "populates change note from details hash" do
        expect { subject }.to change { ChangeNote.count }.by(1)
        expect(ChangeNote.last.note).to eq "Marvellous"
        expect(ChangeNote.last.public_timestamp).to eq(edition.public_updated_at)
      end
    end

    context "edition has an empty change_history entry in details hash" do
      let(:details) { { change_history: [] } }
      it "populates change note from details hash" do
        expect { subject }.to_not change { ChangeNote.count }
      end
    end

    context "edition has a nil change_history entry in details hash" do
      let(:details) { { change_history: nil } }
      it "populates change note from details hash" do
        expect { subject }.to_not change { ChangeNote.count }
      end
    end

    context "edition has change_history entry in details hash" do
      let(:details) do
        {
          change_history: [
            { public_timestamp: 3.day.ago.to_s, note: "note 3" },
            { public_timestamp: 1.day.ago.to_s, note: "note 1" },
            { public_timestamp: 2.days.ago.to_s, note: "note 2" },
          ],
        }
      end

      it "populates change note from most recent history item" do
        expect { subject }.to change { ChangeNote.count }.by(1)
        expect(ChangeNote.last.note).to eq "note 1"
      end
    end
  end
end
