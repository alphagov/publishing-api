require 'rails_helper'

RSpec.describe Presenters::ContentStorePresenter do
  let(:content_item) { create(:live_content_item) }
  let!(:content_store_payload_version) do
    create(:content_store_payload_version, content_item_id: content_item.id)
  end

  it "excludes the update_type from the presentation" do
    presentation = described_class.present(content_item)
    expect(presentation).to_not have_key(:update_type)
  end

  it "leaves other fields intact" do
    presentation = described_class.present(content_item)
    expect(presentation).to have_key(:content_id)
    expect(presentation).to have_key(:title)
    expect(presentation).to have_key(:details)
  end
end
