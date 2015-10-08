require 'rails_helper'

RSpec.describe LinkSet do
  def verify_new_attributes_set
    expect(described_class.first.links[:policies].length).to eq(2)
  end

  def verify_old_attributes_not_preserved
    expect(described_class.first.links[:organisations]).to be_nil
  end

  let(:new_attributes) {
    {
      content_id: content_id,
      links: {
        policies: [ SecureRandom.uuid, SecureRandom.uuid ]
      }
    }
  }

  it_behaves_like Replaceable
end
