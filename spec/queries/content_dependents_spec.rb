require "rails_helper"

RSpec.describe Queries::ContentDependents do
  let(:content_id) { double(:content_id) }
  let(:dependent_lookup) { double(:dependent_lookup, call: ['123']) }
  subject(:dependents) do
    described_class.new(
      content_id: content_id,
      fields: fields,
      dependent_lookup: dependent_lookup
    )
  end

  context "dummy link_sets" do
    let(:fields) { [:title] }
    let(:recursive_link_types) { [:linked_items, :active_top_level_browse_page] }
    let(:direct_link_types) { [:parent] }
    it "calculates the correct link_types" do
      expect(dependent_lookup).to receive(:call).with(
        content_id: content_id,
        recursive_link_types: recursive_link_types,
        direct_link_types: direct_link_types
      )
      dependents.call
    end
  end

  context "field changes that require dependent lookup" do
    let(:fields) { [:base_url, :other_field] }
    it "returns the dependents" do
      expect(dependents.call).to eq(['123'])
    end
  end

  context "field changes that do not require dependent lookup" do
    let(:fields) { [:foo] }
    it "returns no dependents" do
      expect(dependents.call).to eq([])
    end
  end
end
