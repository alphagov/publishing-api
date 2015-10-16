require 'rails_helper'

RSpec.describe LinkSet do
  def set_new_attributes(item)
    item.links = { foo: ["bar"] }
  end

  def verify_new_attributes_set
    expect(described_class.first.links).to eq(foo: ["bar"])
  end

  def verify_old_attributes_not_preserved
    expect(described_class.first.links[:organisations]).to be_nil
  end

  let!(:existing) { create(described_class) }
  let!(:content_id) { existing.content_id }

  let!(:payload) do
    build(described_class)
    .as_json
    .merge(
      content_id: content_id,
      links: {
        foo: ["bar"]
      }
    )
  end

  it_behaves_like Replaceable
end
