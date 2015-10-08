require 'rails_helper'

RSpec.describe Presenters::ContentItemPresenter do
  let(:content_item) { create(:draft_content_item) }

  subject(:presented) { described_class.new(content_item).present }

  it "includes the metadata fields in the top level of the presented item" do
    content_item.metadata.keys.each do |key|
      expect(presented[key]).to eq(content_item.metadata[key])
    end
  end

  it "removes the metadata key" do
    expect(presented).not_to have_key(:metadata)
  end

  it "removes the id key" do
    expect(presented).not_to have_key(:id)
  end

  it "exports all other fields" do
    content_item.attributes.deep_symbolize_keys.each do |key, value|
      next if [:metadata, :id].include?(key)
      expect(presented[key]).to eq(value)
    end
  end
end
