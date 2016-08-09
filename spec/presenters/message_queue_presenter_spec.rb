require 'rails_helper'

RSpec.describe Presenters::MessageQueuePresenter do
  let(:downstream_presenter) {
    web_content_item = Queries::GetWebContentItems.find(FactoryGirl.create(:live_content_item))
    Presenters::DownstreamPresenter.new(web_content_item, nil, state_fallback_order: [:published])
  }

  it "mixes in the specified update_type to the presentation" do
    presentation = described_class.present(downstream_presenter, update_type: "foo")
    expect(presentation[:update_type]).to eq("foo")
  end

  it "leaves other fields intact" do
    presentation = described_class.present(downstream_presenter, update_type: "foo")
    expect(presentation).to have_key(:content_id)
    expect(presentation).to have_key(:title)
    expect(presentation).to have_key(:details)
  end
end
