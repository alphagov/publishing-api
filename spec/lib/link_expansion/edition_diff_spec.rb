RSpec.describe LinkExpansion::EditionDiff do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id: content_id) }

  let!(:previous_edition) do
    create(
      :superseded_edition,
      document: document,
      title: "Foo",
      base_path: "/foo",
    )
  end

  let!(:current_edition) do
    create(
      :live_edition,
      document: document,
      title: "Bar",
      base_path: "/foo",
      user_facing_version: 2,
    )
  end

  let(:new_draft_edition) do
    create(
      :draft_edition,
      document: document,
      title: "Bar",
      base_path: "/foo",
      user_facing_version: 3,
      public_updated_at: current_edition.public_updated_at,
      first_published_at: current_edition.first_published_at,
    )
  end

  subject { described_class.new(current_edition) }

  shared_examples "should have changes" do
    it "should have changes" do
      expect(subject.present?).to eq(true)
    end
  end

  shared_examples "shouldn't have changes" do
    it "shouldn't have changes" do
      expect(subject.present?).to eq(false)
    end
  end

  context "diff in title" do
    include_examples "should have changes"

    it "should have the correct changed fields" do
      expect(subject.fields).to eq(%i[title])
    end
  end

  context "diff in title, document_type and base_path" do
    let!(:current_edition) do
      create(
        :live_edition,
        document: document,
        title: "Bar",
        base_path: "/bar",
        user_facing_version: 2,
        document_type: "new_type",
      )
    end

    include_examples "should have changes"

    it "should have the correct changed fields" do
      expect(subject.fields).to match_array(%i[api_path base_path document_type title])
    end
  end

  context "diff in details when a finder" do
    let!(:current_edition) do
      create(
        :live_edition,
        document: document,
        user_facing_version: 2,
        document_type: "finder",
        base_path: "/foo",
        details: { facets: [2] },
      )
    end

    include_examples "should have changes"

    it "should have the correct changed fields" do
      expect(subject.fields).to match_array(%i[details document_type title])
    end
  end

  context "diff inside details hash" do
    let!(:previous_edition) do
      create(
        :superseded_edition,
        document: document,
        document_type: "travel_advice",
        base_path: "/foo",
        details: { country: "en" },
      )
    end

    context "with a field that matters" do
      let!(:current_edition) do
        create(
          :live_edition,
          document: document,
          user_facing_version: 2,
          document_type: "travel_advice",
          base_path: "/foo",
          details: { country: "fr" },
        )
      end

      include_examples "should have changes"

      it "should have the correct changed fields" do
        expect(subject.fields).to eq(%i[details])
      end
    end

    context "with a field that doesn't matter" do
      let!(:current_edition) do
        create(
          :live_edition,
          document: document,
          user_facing_version: 2,
          document_type: "travel_advice",
          base_path: "/foo",
          details: { country: "en", unrelated_field: "en" },
        )
      end

      include_examples "shouldn't have changes"
    end
  end

  context "multiple versions" do
    before { current_edition.supersede }
    subject { described_class.new(new_draft_edition) }
    include_examples "shouldn't have changes"
  end

  context "no previous item" do
    let!(:previous_edition) { nil }
    include_examples "should have changes"
  end

  context "provide the edition to compare" do
    context "given an empty hash" do
      subject { described_class.new(new_draft_edition, previous_edition: {}) }
      include_examples "should have changes"
    end

    context "given an edition" do
      let(:presented_item) { new_draft_edition.to_h.deep_stringify_keys }
      subject { described_class.new(new_draft_edition, previous_edition: presented_item) }
      include_examples "shouldn't have changes"
    end
  end
end
