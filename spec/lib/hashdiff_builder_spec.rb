require "rails_helper"

RSpec.describe HashdiffBuilder do
  let(:content_id) { SecureRandom.uuid }
  let(:organisation_links) do
    [
      OpenStruct.new(
        target_content_id: content_id,
        link_type: "organisations"
      )
    ]
  end

  let(:policy_areas_links) do
    [
      OpenStruct.new(
        target_content_id: content_id,
        link_type: "policy_areas"
      )
    ]
  end

  let(:previous_edition) do
    double(
      :edition,
      description: "A description",
      title: "A title",
      links: organisation_links
    )
  end

  let(:updated_edition) do
    double(
      :edition,
      description: "A description",
      title: "A new title",
      links: policy_areas_links
    )
  end

  let(:presented_previous_edition) do
    {
      title: "A title",
      links: { organisations: [content_id] }
    }
  end

  let(:presented_updated_edition) do
    {
      title: "A new title",
      links: { policy_areas: [content_id] },
    }
  end

  describe "#diff" do
    let(:presenter) { double("presenter") }
    let(:hash_diff) { described_class.new(presenter) }
    subject { hash_diff.diff }

    context "when a previous item and current item is provided" do
      before do
        allow(presenter).to receive(:call).with(previous_edition).and_return(presented_previous_edition)
        allow(presenter).to receive(:call).with(updated_edition).and_return(presented_updated_edition)
        hash_diff.previous_item = previous_edition
        hash_diff.current_item = updated_edition
      end

      let(:previous_and_updated_diff) do
        [
          ["~", [:title], "A title", "A new title"],
          ["-", %i[links organisations], [content_id]],
          ["+", %i[links policy_areas], [content_id]]
        ]
      end

      it { is_expected.to match_array(previous_and_updated_diff) }
    end

    context "when no previous item is provided" do
      it "raises a 'MissingItemError' error" do
        expect { subject }.to raise_error(HashdiffBuilder::MissingItemError, "No previous item provided")
      end
    end

    context "when no current item is provided" do
      before do
        allow(presenter).to receive(:call).with(previous_edition).and_return(presented_previous_edition)
        hash_diff.previous_item = previous_edition
      end

      it "raises a 'MissingItemError' error" do
        expect { subject }.to raise_error(HashdiffBuilder::MissingItemError, "No current item provided")
      end
    end
  end
end
