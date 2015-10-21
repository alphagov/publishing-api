require 'rails_helper'

RSpec.describe Presenters::ContentItemPresenter do
  let(:content_item_hash) { create(:draft_content_item).as_json.deep_symbolize_keys }
  let(:content_item_metadata) { content_item_hash.fetch(:metadata) }

  let(:presented) { subject.present(content_item_hash) }

  it "includes the metadata fields in the top level of the presented item" do
    content_item_metadata.keys.each do |key|
      next if key == :update_type
      expect(presented[key]).to eq(content_item_metadata[key])
    end
  end

  it "removes the metadata key" do
    expect(presented).not_to have_key(:metadata)
  end

  it "removes the id key" do
    expect(presented).not_to have_key(:id)
  end

  it "removes the version" do
    expect(presented).not_to have_key(:version)
  end

  it "removes the update_type" do
    expect(presented).not_to have_key(:update_type)
  end

  it "exports date fields as ISO 8601" do
    expect(presented[:public_updated_at]).to be_a(String)
    expect(presented[:public_updated_at]).to eq(content_item_hash[:public_updated_at].iso8601)
  end

  it "exports all other fields" do
    content_item_hash.each do |key, value|
      next if [:metadata, :id, :version, :public_updated_at, :update_type].include?(key)
      expect(presented[key]).to eq(value)
    end
  end
end
