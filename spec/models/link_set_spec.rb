require 'rails_helper'

RSpec.describe LinkSet do
  def set_new_attributes(item)
    item.links = { foo: ["bar"] }
  end

  def verify_new_attributes_set
    expect(described_class.last.links).to eq(foo: ["bar"])
  end

  def verify_old_attributes_not_preserved
    expect(described_class.last.links[:organisations]).to be_nil
  end

  let!(:existing) { create(described_class) }
  let!(:content_id) { existing.content_id }

  let!(:payload) do
    FactoryGirl.build(:link_set)
    .as_json
    .merge(
      content_id: content_id,
      links: {
        foo: ["bar"]
      }
    )
  end

  let!(:another_payload) do
    FactoryGirl.build(:link_set)
    .as_json
    .symbolize_keys
    .merge(
      links: {
        foo: ["bar"]
      }
    )
  end

  it_behaves_like Replaceable
end
