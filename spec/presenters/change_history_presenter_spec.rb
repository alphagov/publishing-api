RSpec.describe Presenters::ChangeHistoryPresenter do
  let(:document) { create(:document) }
  let(:edition) do
    create(
      :edition,
      document: document,
      details: details.deep_stringify_keys,
    )
  end
  let(:details) { {} }
  subject { described_class.new(edition).change_history }

  describe "#change_history" do
    context "details hash includes content_history" do
      let(:details) do
        { change_history: [
          { public_timestamp: 1.day.ago.to_s, note: "note 1" },
          { public_timestamp: 2.days.ago.to_s, note: "note 2" },
        ] }
      end
      it "returns content_history from details hash" do
        expect(subject).to eq details[:change_history]
      end
    end

    context "details hash doesn't include content_history" do
      before do
        2.times do |i|
          ChangeNote.create(
            edition: edition,
            note: i.to_s,
            public_timestamp: Time.zone.now.utc,
          )
        end
      end
      it "constructs content history from change notes" do
        expect(subject.map { |item| item[:note] }).to eq %w[0 1]
      end
    end

    it "orders change notes by public_timestamp (ascending)" do
      [1, 3, 2].to_a.each do |i|
        ChangeNote.create(
          edition: edition,
          note: i.to_s,
          public_timestamp: i.days.ago,
        )
      end
      expect(subject.map { |item| item[:note] }).to eq %w[3 2 1]
    end

    it "omits change notes that don't have a public timestamp" do
      create(:change_note, edition: edition, note: "with-timestamp", public_timestamp: 1.day.ago)
      create(:change_note, edition: edition, note: "without-timestamp", public_timestamp: nil)
      expect(subject.map { |item| item[:note] }).to eq %w[with-timestamp]
    end

    context "multiple editions for a single content id" do
      let(:item1) do
        create(
          :superseded_edition,
          document: document,
          details: details,
          user_facing_version: 1,
        )
      end
      let(:item2) do
        create(
          :live_edition,
          document: document,
          details: details,
          user_facing_version: 2,
        )
      end
      before do
        ChangeNote.create!(edition: item1)
        ChangeNote.create!(edition: item2)
      end

      context "reviewing latest version of a edition" do
        it "constructs content history from all change notes for content id" do
          expect(described_class.new(item2).change_history.count).to eq 2
        end
      end

      context "reviewing older version of a edition" do
        it "doesn't include change notes corresponding to newer versions" do
          expect(described_class.new(item1).change_history.count).to eq 1
        end
      end
    end
  end
end
