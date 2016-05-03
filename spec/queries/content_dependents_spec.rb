require "rails_helper"

RSpec.describe Queries::ContentDependents do
  let(:content_item) { FactoryGirl.create(:content_item) }
  let(:link_set) { FactoryGirl.create(:link_set, content_id: content_id) }
  let!(:link_2) { FactoryGirl.create(:link, link_set: link_set, link_type: 'topical_event') }
  let!(:link) { FactoryGirl.create(:link, link_set: link_set, link_type: 'special') }
  let(:content_id) { content_item.content_id }
  let(:dependent_lookup) { double(:dependent_lookup, call: ['123']) }

  subject(:dependents) do
    described_class.new(
      content_id: content_id,
      fields: fields,
      dependent_lookup: dependent_lookup
    )
  end

  context "link_sets" do
    let(:fields) { [:base_path] }
    let(:direct_link_types) { %w(topical_event special) }
    it "calculates the correct link_types" do
      expect(dependent_lookup).to receive(:call).with(
        content_id: content_id,
        recursive_link_types: [],
        direct_link_types: direct_link_types
      )
      dependents.call
    end
  end

  context "field changes that require dependent lookup" do
    let(:fields) { [:base_path, :other_field] }
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
