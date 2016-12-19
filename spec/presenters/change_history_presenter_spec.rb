require "rails_helper"

RSpec.describe Presenters::ChangeHistoryPresenter do
  let(:content_id) { SecureRandom.uuid }
  let(:content_item) do
    FactoryGirl.create(
      :content_item,
      details: details.deep_stringify_keys,
      content_id: content_id,
    )
  end
  let(:details) { {} }
  subject { described_class.new(content_item).change_history }

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
            content_item: content_item,
            content_id: content_item.content_id,
            note: i.to_s,
            public_timestamp: Time.now.utc
          )
        end
      end
      it "constructs content history from change notes" do
        expect(subject.map { |item| item[:note] }).to eq %w(0 1)
      end
    end

    it "orders change notes by public_timestamp (ascending)" do
      [1, 3, 2].to_a.each do |i|
        ChangeNote.create(
          content_item: content_item,
          content_id: content_item.content_id,
          note: i.to_s,
          public_timestamp: i.days.ago
        )
      end
      expect(subject.map { |item| item[:note] }).to eq %w(3 2 1)
    end

    context "multiple content items for a single content id" do
      let(:item1) do
        FactoryGirl.create(
          :content_item,
          details: details,
          content_id: content_id,
          user_facing_version: 1
        )
      end
      let(:item2) do
        FactoryGirl.create(
          :content_item,
          details: details,
          content_id: content_id,
          user_facing_version: 2,
          state: "published"
        )
      end
      before do
        ChangeNote.create(content_item: item1, content_id: content_id)
        ChangeNote.create(content_item: item2, content_id: content_id)
        ChangeNote.create(content_id: content_id)
      end

      context "reviewing latest version of a content item" do
        it "constructs content history from all change notes for content id" do
          expect(described_class.new(item2).change_history.count).to eq 3
        end
      end

      context "reviewing older version of a content item" do
        it "doesn't include change notes corresponding to newer versions" do
          expect(described_class.new(item1).change_history.count).to eq 2
        end
      end
    end
  end
end
