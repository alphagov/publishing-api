require 'rails_helper'

RSpec.describe LinkExpansion::EditionDiff do
  let(:content_id) { SecureRandom.uuid }
  let(:document) { create(:document, content_id: content_id) }

  let!(:previous_edition) do
    create(:superseded_edition, document: document,
                       title: "Foo", base_path: "/foo")
  end

  let!(:current_edition) do
    create(:live_edition, document: document,
                       title: "Bar", base_path: "/foo",
                       user_facing_version: 2)
  end

  let(:new_draft_edition) do
    create(:draft_edition, document: document,
                       title: "Bar", base_path: "/foo",
                       user_facing_version: 3)
  end

  subject { described_class.new(current_edition) }

  shared_examples "should update dependencies" do
    it "should update dependencies" do
      expect(subject.should_update_dependencies?).to eq(true)
    end
  end

  shared_examples "shouldn't update dependencies" do
    it "shouldn't update dependencies" do
      expect(subject.should_update_dependencies?).to eq(false)
    end
  end

  context "diff in title" do
    include_examples "should update dependencies"
  end

  context "diff in title, document_type and base_path" do
    let!(:current_edition) do
      create(
        :live_edition,
        document: document,
        title: "Bar",
        base_path: "/bar",
        user_facing_version: 2,
        document_type: "new_type"
      )
    end

    include_examples "should update dependencies"
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

    include_examples "should update dependencies"
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

      include_examples "should update dependencies"
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

      include_examples "shouldn't update dependencies"
    end
  end

  context "multiple versions" do
    before { current_edition.supersede }
    subject { described_class.new(new_draft_edition) }
    include_examples "shouldn't update dependencies"
  end

  context "no previous item" do
    let!(:previous_edition) { nil }
    include_examples "should update dependencies"
  end

  context "provide the edition to compare" do
    context "given an empty hash" do
      subject { described_class.new(new_draft_edition, previous_edition: {}) }
      include_examples "should update dependencies"
    end

    context "given an edition" do
      let(:presented_item) { new_draft_edition.to_h.deep_stringify_keys }
      subject { described_class.new(new_draft_edition, previous_edition: presented_item) }
      include_examples "shouldn't update dependencies"
    end
  end
end
