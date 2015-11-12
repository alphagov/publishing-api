require 'rails_helper'

RSpec.describe Presenters::MessageQueuePresenter do
  let(:content_item) { FactoryGirl.create(:live_content_item) }

  it "mixes in the specified update_type to the presentation" do
    presentation = described_class.present(content_item, update_type: "foo")
    expect(presentation[:update_type]).to eq("foo")
  end

  it "leaves other fields intact" do
    presentation = described_class.present(content_item, update_type: "foo")
    expect(presentation).to have_key(:content_id)
    expect(presentation).to have_key(:title)
    expect(presentation).to have_key(:details)
  end
end
