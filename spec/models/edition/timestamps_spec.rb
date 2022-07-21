RSpec.describe Edition::Timestamps do
  before { Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0)) }
  after { Timecop.return }
  let(:current_time) { Time.zone.now }

  describe "#edited" do
    let(:edition) { build(:edition, update_type:) }
    let(:previous_live_version) do
      build(
        :edition,
        publishing_api_first_published_at: "2017-01-01",
        first_published_at: "2017-04-01",
        major_published_at: "2017-11-11",
      )
    end

    let(:update_type) { "major" }
    let(:payload) do
      {
        first_published_at:,
        last_edited_at:,
        public_updated_at:,
      }
    end
    let(:first_published_at) { nil }
    let(:last_edited_at) { nil }
    let(:public_updated_at) { nil }

    before { described_class.edited(edition, payload, previous_live_version) }

    it "saves the edition" do
      expect(edition.id).not_to be_nil
    end

    it "sets publishing_api_last_edited_at to current time" do
      expect(edition.publishing_api_last_edited_at).to eq current_time
    end

    it "sets publishing_api_first_published_at to same value as previous_live_version" do
      expect(edition.publishing_api_first_published_at).to eq previous_live_version.publishing_api_first_published_at
    end

    context "when previous_live_version is nil" do
      let(:previous_live_version) { nil }

      it "sets publishing_api_first_published_at to nil" do
        expect(edition.publishing_api_first_published_at).to be_nil
      end
    end

    context "when edition has an update_type that is not major" do
      let(:update_type) { "minor" }

      it "sets major_published_at to same value as previous_live_version" do
        expect(edition.major_published_at).to eq previous_live_version.major_published_at
      end
    end

    context "when first_published_at is provided in payload" do
      let(:first_published_at) { "2017-12-25" }

      it "sets first_published_at to provided value" do
        expect(edition.first_published_at).to eq Time.zone.parse(first_published_at)
      end
    end

    context "when first_published_at is not provided in payload" do
      let(:first_published_at) { nil }

      it "sets first_published_at to previous_live_version" do
        expect(edition.first_published_at).to eq previous_live_version.first_published_at
      end
    end

    context "when last_edited_at is provided in payload" do
      let(:last_edited_at) { "2017-10-30" }

      it "sets last_edited_at to provided value" do
        expect(edition.last_edited_at).to eq Time.zone.parse(last_edited_at)
      end
    end

    context "when last_edited_at is not provided in payload" do
      let(:last_edited_at) { nil }

      it "sets last_edited_at to current time" do
        expect(edition.last_edited_at).to eq current_time
      end
    end

    context "when public_updated_at is provided in payload" do
      let(:public_updated_at) { "2017-10-30" }

      it "sets public_updated_at to provided value" do
        expect(edition.public_updated_at).to eq Time.zone.parse(public_updated_at)
      end
    end

    context "when public_updated_at is not provided in payload" do
      let(:public_updated_at) { nil }

      it "sets public_updated_at to nil" do
        expect(edition.public_updated_at).to be_nil
      end
    end
  end

  describe "#live_transition" do
    let(:edition) do
      build(
        :edition,
        publishing_api_first_published_at:,
        first_published_at:,
        public_updated_at:,
      )
    end
    let(:publishing_api_first_published_at) { nil }
    let(:first_published_at) { nil }
    let(:public_updated_at) { nil }

    let(:previous_live_version) do
      build(
        :edition,
        major_published_at: "2017-11-05",
        public_updated_at: previous_public_updated_at,
      )
    end
    let(:previous_public_updated_at) { "2017-10-30" }

    let(:update_type) { "major" }

    before { described_class.live_transition(edition, update_type, previous_live_version) }

    it "saves the edition" do
      expect(edition.id).not_to be_nil
    end

    it "sets the published_at value to current time" do
      expect(edition.published_at).to eq current_time
    end

    context "when the edition is being published for the first time" do
      let(:publishing_api_first_published_at) { nil }
      let(:first_published_at) { nil }

      it "sets publishing_api_first_published_at to current time" do
        expect(edition.publishing_api_first_published_at).to eq current_time
      end

      it "sets first_published_at to current time" do
        expect(edition.first_published_at).to eq current_time
      end
    end

    context "when an edition has already been published" do
      let(:publishing_api_first_published_at) { "2010-05-01" }
      let(:first_published_at) { "2011-05-01" }

      it "doesn't change publishing_api_first_published_at" do
        expect(edition.publishing_api_first_published_at).to eq Time.zone.parse(publishing_api_first_published_at)
      end

      it "doesn't change first published at" do
        expect(edition.first_published_at).to eq Time.zone.parse(first_published_at)
      end
    end

    context "when update type is major" do
      it "sets major_published_at to current time" do
        expect(edition.major_published_at).to eq current_time
      end

      context "and public_updated_at hasn't been set on edition" do
        let(:public_updated_at) { nil }

        it "sets public_updated_at to current time" do
          expect(edition.public_updated_at).to eq current_time
        end
      end

      context "and public_updated_at has been set on the edition" do
        let(:public_updated_at) { "2017-04-01" }

        it "doesn't change public_updated_at" do
          expect(edition.public_updated_at).to eq Time.zone.parse(public_updated_at)
        end
      end
    end

    context "when update type is not major" do
      let(:update_type) { "minor" }

      it "sets major_published_at to the value from the previous live edition" do
        expect(edition.major_published_at).to eq previous_live_version.major_published_at
      end

      context "and public_updated_at isn't set, also previous live edition has a public_updated_at value" do
        let(:public_updated_at) { nil }
        let(:previous_public_updated_at) { "2017-07-03" }

        it "sets public_updated_at to the value of the previous edition" do
          expect(edition.public_updated_at).to eq previous_live_version.public_updated_at
        end
      end

      context "and neither edition or previous live edition have a public_updated_at value" do
        let(:first_published_at) { "2017-01-01" }
        let(:public_updated_at) { nil }
        let(:previous_public_updated_at) { nil }

        it "sets public_updated_at to first_published_at" do
          expect(edition.public_updated_at).to eq Time.zone.parse(first_published_at)
        end
      end

      context "and public_updated_at has been set on the edition" do
        let(:public_updated_at) { "2017-04-01" }

        it "doesn't change public_updated_at" do
          expect(edition.public_updated_at).to eq Time.zone.parse(public_updated_at)
        end
      end
    end
  end
end
