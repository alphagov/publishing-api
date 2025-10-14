RSpec.describe Presenters::Queries::ChangeHistory do
  let(:document) { create(:document) }

  let(:edition) do
    create(:edition, document:, state: "published", user_facing_version: "2")
  end

  let(:subject) { described_class.new(edition, include_edition_change_history:).call }

  describe "when there are no embed links" do
    context "when include_edition_change_history is true" do
      let(:include_edition_change_history) { true }

      it "constructs content history from change notes" do
        2.times do |i|
          create(:change_note, edition:, note: i.to_s, public_timestamp: Time.zone.now.utc)
        end
        expect(subject.map(&:note)).to eq %w[0 1]
      end

      it "orders change notes by public_timestamp (ascending)" do
        [1, 3, 2].to_a.each do |i|
          create(:change_note, edition:, note: i.to_s, public_timestamp: i.days.ago)
        end
        expect(subject.map(&:note)).to eq %w[3 2 1]
      end

      it "omits change notes that don't have a public timestamp" do
        create(:change_note, edition:, note: "with-timestamp", public_timestamp: 1.day.ago)
        create(:change_note, edition:, note: "without-timestamp", public_timestamp: nil)
        expect(subject.map(&:note)).to eq %w[with-timestamp]
      end
    end

    context "when include_edition_change_history is false" do
      let(:include_edition_change_history) { false }

      it "should return no change notes" do
        expect(subject.map(&:note)).to eq []
      end
    end
  end

  describe "when links exist" do
    before do
      content_block = create(:edition, created_at: 2.weeks.ago)
      older_edition = create(:edition, document:, created_at: 2.days.ago, state: "superseded", user_facing_version: "1", content_store: nil)

      # This is where the document was first linked with the content_block
      create(:link,
             edition: older_edition,
             target_content_id: content_block.content_id,
             link_type: "embed",
             created_at: 3.days.ago)

      create(:link,
             edition: edition,
             target_content_id: content_block.content_id,
             link_type: "embed",
             created_at: 1.day.ago)

      # This link should not be included
      create(:link,
             edition: edition,
             target_content_id: content_block.content_id,
             link_type: "ministers")

      # Create change notes for the content block - the first one was created before the document was linked, so should
      # not show
      create(:change_note, edition: content_block, note: "should-not-show", public_timestamp: 1.week.ago)
      create(:change_note, edition: content_block, note: "linked-edition-note-1", public_timestamp: 2.days.ago)
      create(:change_note, edition: content_block, note: "linked-edition-note-2", public_timestamp: 1.day.ago)

      # Create change notes for the editions
      create(:change_note, edition: older_edition, note: "note-2", public_timestamp: 3.days.ago)
      create(:change_note, edition:, note: "note-1", public_timestamp: 1.hour.ago)
    end
    context "when include_edition_change_history is true" do
      let(:include_edition_change_history) { true }

      it "should include change notes that were created after the link was created" do
        expect(subject.map(&:note)).to eq %w[note-2 linked-edition-note-1 linked-edition-note-2 note-1]
      end
    end

    context "when include_edition_change_history is false" do
      let(:include_edition_change_history) { false }

      it "should only include the change notes for the linked editions" do
        expect(subject.map(&:note)).to eq %w[linked-edition-note-1 linked-edition-note-2]
      end
    end
  end
end
