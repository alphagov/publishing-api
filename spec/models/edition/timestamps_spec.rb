RSpec.describe Edition::Timestamps do
  before { Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0)) }
  after { Timecop.return }
  let(:current_time) { Time.zone.now }

  describe "#edited" do
    it "saves the edition" do
      edition = build(:edition)
      described_class.edited(edition, {})
      expect(edition.id).not_to be_nil
    end

    it "sets publishing_api_last_edited_at to current time" do
      edition = build(:edition)
      described_class.edited(edition, {})
      expect(edition.publishing_api_last_edited_at).to eq current_time
    end

    it "sets publishing_api_first_published_at to same value as previous_live_version" do
      edition = build(:edition)
      previous_live_version = build(:edition, publishing_api_first_published_at: "2017-01-01")
      described_class.edited(edition, {}, previous_live_version)
      expect(edition.publishing_api_first_published_at).to eq(Time.zone.parse("2017-01-01"))
    end

    it "sets publishing_api_first_published_at to nil when there isn't a previous live version" do
      edition = build(:edition)
      described_class.edited(edition, {})
      expect(edition.publishing_api_first_published_at).to be_nil
    end

    it "sets major_published_at to same value as previous_live_version for a non major update" do
      edition = build(:edition, update_type: "minor")
      previous_live_version = build(:edition, major_published_at: "2017-01-01")
      described_class.edited(edition, {}, previous_live_version)
      expect(edition.major_published_at).to eq(Time.zone.parse("2017-01-01"))
    end

    it "sets first_published_at when it's provided in the payload" do
      edition = build(:edition)
      described_class.edited(edition, { first_published_at: "2017-01-01" })
      expect(edition.first_published_at).to eq(Time.zone.parse("2017-01-01"))
    end

    it "sets first_published_at to the previous_live_version's value when it's not in the payload" do
      edition = build(:edition)
      previous_live_version = build(:edition, first_published_at: "2017-01-02")
      described_class.edited(edition, {}, previous_live_version)
      expect(edition.first_published_at).to eq(Time.zone.parse("2017-01-02"))
    end

    it "sets last_edited_at to a value provided in the payload" do
      edition = build(:edition)
      described_class.edited(edition, { last_edited_at: "2017-01-01" })
      expect(edition.last_edited_at).to eq(Time.zone.parse("2017-01-01"))
    end

    it "sets last_edited_at to current time when it's not in the payload" do
      edition = build(:edition)
      described_class.edited(edition, {})
      expect(edition.last_edited_at).to eq(current_time)
    end

    it "sets public_updated_at to a value provided in the payload" do
      edition = build(:edition)
      described_class.edited(edition, { public_updated_at: "2017-01-01" })
      expect(edition.public_updated_at).to eq(Time.zone.parse("2017-01-01"))
    end

    it "leaves public_updated_at as nil when it's not in the payload" do
      edition = build(:edition)
      described_class.edited(edition, {})
      expect(edition.public_updated_at).to be_nil
    end
  end

  describe "#live_transition" do
    it "saves the edition" do
      edition = build(:edition)
      described_class.live_transition(edition, "minor")
      expect(edition.id).not_to be_nil
    end

    it "sets the published_at value to current time" do
      edition = build(:edition)
      described_class.live_transition(edition, "minor")
      expect(edition.published_at).to eq current_time
    end

    context "when the edition is being published for the first time" do
      let(:edition) { build(:edition) }

      it "sets publishing_api_first_published_at to current time" do
        described_class.live_transition(edition, "minor")
        expect(edition.publishing_api_first_published_at).to eq current_time
      end

      it "sets first_published_at to current time" do
        described_class.live_transition(edition, "minor")
        expect(edition.first_published_at).to eq current_time
      end
    end

    context "when an edition has already been published" do
      let(:edition) do
        build(
          :edition,
          publishing_api_first_published_at: "2011-05-01",
          first_published_at: "2011-10-01",
        )
      end

      it "doesn't change publishing_api_first_published_at" do
        described_class.live_transition(edition, "minor")
        expect(edition.publishing_api_first_published_at).to eq Time.zone.parse("2011-05-01")
      end

      it "doesn't change first published at" do
        described_class.live_transition(edition, "minor")
        expect(edition.first_published_at).to eq Time.zone.parse("2011-10-01")
      end
    end

    context "when update type is major" do
      it "sets major_published_at to current time" do
        edition = build(:edition)
        described_class.live_transition(edition, "major")
        expect(edition.major_published_at).to eq(current_time)
      end

      it "sets public_updated_at to current time when not already set" do
        edition = build(:edition, public_updated_at: nil)
        described_class.live_transition(edition, "major")
        expect(edition.public_updated_at).to eq(current_time)
      end

      it "doesn't change an already set public_updated_at" do
        edition = build(:edition, public_updated_at: "2017-04-01")
        described_class.live_transition(edition, "major")
        expect(edition.public_updated_at).to eq(Time.zone.parse("2017-04-01"))
      end
    end

    context "when update type is not major" do
      it "sets major_published_at to the previous_live_edition's value" do
        edition = build(:edition)
        previous_live_version = build(:edition, major_published_at: "2017-01-02")
        described_class.live_transition(edition, "minor", previous_live_version)
        expect(edition.major_published_at).to eq(previous_live_version.major_published_at)
      end

      it "doesn't set major_published_at if there isn't a previous_live_edition" do
        edition = build(:edition)
        described_class.live_transition(edition, "minor")
        expect(edition.major_published_at).to be_nil
      end

      it "doesn't change an already set public_updated_at" do
        edition = build(:edition, public_updated_at: "2017-04-01")
        described_class.live_transition(edition, "minor")
        expect(edition.public_updated_at).to eq(Time.zone.parse("2017-04-01"))
      end

      it "sets public_updated_at based on a previous_live_edition if it exists" do
        edition = build(:edition, public_updated_at: "2017-04-01")
        described_class.live_transition(edition, "minor")
        expect(edition.public_updated_at).to eq(Time.zone.parse("2017-04-01"))
      end

      it "sets public_updated_at to current time if a previous_live_edition doesn't exist" do
        edition = build(:edition)
        described_class.live_transition(edition, "minor")
        expect(edition.public_updated_at).to eq(current_time)
      end
    end

    it "sets the public_timestamp of a change note without one" do
      edition = create(:edition, public_updated_at: "2022-07-18")
      change_note = create(:change_note, edition: edition, public_timestamp: nil)
      expect { described_class.live_transition(edition, "minor") }
        .to change { change_note.reload.public_timestamp }.to(edition.public_updated_at)
    end

    it "doesn't change the public_timestamp of a change note with one already set" do
      edition = create(:edition)
      change_note = create(:change_note, edition: edition, public_timestamp: "2022-07-18")
      expect { described_class.live_transition(edition, "minor") }
        .not_to(change { change_note.reload.public_timestamp })
    end
  end
end
