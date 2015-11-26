require 'rails_helper'

RSpec.describe LinkSet do
  context "it behaves like a replaceable" do
    let!(:existing) { create(:link_set) }
    let!(:content_id) { existing.content_id }

    let!(:payload) do
      { content_id: content_id }
    end

    let!(:another_payload) do
      { content_id: SecureRandom.uuid }
    end

    it_behaves_like Replaceable

    # We are not setting extra attributes on the LinkSet model.
    def set_new_attributes(item)
    end
    def verify_new_attributes_set
    end
  end
end
