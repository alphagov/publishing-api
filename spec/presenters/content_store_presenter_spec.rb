require 'rails_helper'

RSpec.describe Presenters::ContentStorePresenter do
  let(:downstream_presenter) {
    web_content_item = Queries::GetWebContentItems.find(FactoryGirl.create(:live_content_item).id)
    Presenters::DownstreamPresenter.new(web_content_item, nil, state_fallback_order: [:published])
  }
  let(:event) { double(:event, id: 123) }

  it "excludes the update_type from the presentation" do
    presentation = described_class.present(downstream_presenter, event)
    expect(presentation).to_not have_key(:update_type)
  end

  it "leaves other fields intact" do
    presentation = described_class.present(downstream_presenter, event)
    expect(presentation).to have_key(:content_id)
    expect(presentation).to have_key(:title)
    expect(presentation).to have_key(:details)
  end
end
