RSpec.describe Presenters::ChangeHistoryPresenter do
  let(:document) { build(:document) }
  let(:edition) do
    build(
      :edition,
      document:,
      details: details.deep_stringify_keys,
    )
  end
  subject { described_class.new(edition).change_history }

  let(:change_history_stub) { double("Presenters::Queries::ChangeHistory", call: query_response) }

  describe "#change_history" do
    context "when the details hash does not have a change history" do
      let(:details) { {} }
      let(:change_notes) do
        [
          build(:change_note, note: "Note 1", public_timestamp: 3.days.ago),
          build(:change_note, note: "Note 2", public_timestamp: 2.days.ago),
          build(:change_note, note: "Note 3", public_timestamp: 1.day.ago),
        ]
      end

      let(:query_response) { change_notes }

      before do
        expect(Presenters::Queries::ChangeHistory).to receive(:new)
                                                        .with(edition, include_edition_change_history: true)
                                                        .and_return(change_history_stub)
      end

      it "returns the change notes from the database sorted by date" do
        expect(subject).to eq([
          { public_timestamp: change_notes[2].public_timestamp.utc.iso8601, note: change_notes[2].note },
          { public_timestamp: change_notes[1].public_timestamp.utc.iso8601, note: change_notes[1].note },
          { public_timestamp: change_notes[0].public_timestamp.utc.iso8601, note: change_notes[0].note },
        ])
      end
    end

    context "when the details hash has a change history" do
      let(:one_day_ago) { 1.day.ago }
      let(:two_days_ago) { 2.days.ago }

      let(:details) do
        { change_history: [
          { public_timestamp: one_day_ago.in_time_zone("GMT").to_s, note: "note 1" },
          { public_timestamp: two_days_ago.in_time_zone("GMT").to_s, note: "note 2" },
        ] }
      end

      before do
        expect(Presenters::Queries::ChangeHistory).to receive(:new)
                                                        .with(edition, include_edition_change_history: false)
                                                        .and_return(change_history_stub)
      end

      context "when change notes do not exist for linked editions" do
        let(:query_response) { [] }

        it "returns content_history from details hash" do
          expect(subject).to eq([
            { public_timestamp: one_day_ago.utc.iso8601, note: "note 1" },
            { public_timestamp: two_days_ago.utc.iso8601, note: "note 2" },
          ])
        end
      end

      context "when change notes exist for linked editions" do
        let(:query_response) do
          [
            build(:change_note, public_timestamp: 4.days.ago),
            build(:change_note, public_timestamp: 1.hour.ago),
          ]
        end

        it "merges the original change notes with the change notes from the linked editions in date order" do
          expect(subject).to eq([
            { public_timestamp: query_response[1].public_timestamp.utc.iso8601, note: query_response[1].note },
            { public_timestamp: one_day_ago.utc.iso8601, note: "note 1" },
            { public_timestamp: two_days_ago.utc.iso8601, note: "note 2" },
            { public_timestamp: query_response[0].public_timestamp.utc.iso8601, note: query_response[0].note },
          ])
        end
      end
    end
  end
end
