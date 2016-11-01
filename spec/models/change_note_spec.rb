require "rails_helper"

RSpec.describe ChangeNote do
  let(:payload) { { change_note: payload_change_note } }
  let(:details) { {} }
  let(:payload_change_note) { nil }
  let(:update_type) { "major" }
  let(:content_item) do
    FactoryGirl.create(:content_item, update_type: update_type, details: details)
  end

  describe ".create_from_content_item" do
    subject { described_class.create_from_content_item(payload, content_item) }

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
    end

    context "content item has change_note entry in details hash" do
      let(:details) { { change_note: "Marvellous" }.stringify_keys }
      it "populates change note from details hash" do
        expect { subject }.to change { ChangeNote.count }.by(1)
        expect(ChangeNote.last.note).to eq "Marvellous"
      end
    end

    context "content item has change_note entry in details hash" do
      let(:details) { { change_history: [] } }
      it "populates change note from details hash" do
        expect { subject }.to_not change { ChangeNote.count }
      end
    end

    context "content item has change_note entry in details hash" do
      let(:details) { { change_history: nil } }
      it "populates change note from details hash" do
        expect { subject }.to_not change { ChangeNote.count }
      end
    end

    context "content item has change_history entry in details hash" do
      let(:details) do
        { change_history: [
          { public_timestamp: 3.day.ago.to_s, note: "note 3" },
          { public_timestamp: 1.day.ago.to_s, note: "note 1" },
          { public_timestamp: 2.days.ago.to_s, note: "note 2" },
        ] }
      end
      it "populates change note from most recent history item" do
        expect { subject }.to change { ChangeNote.count }.by(1)
        expect(ChangeNote.last.note).to eq "note 1"
      end
    end
  end
end
