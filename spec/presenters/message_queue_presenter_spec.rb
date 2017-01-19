require 'rails_helper'

RSpec.describe Presenters::MessageQueuePresenter do
  let(:downstream_presenter) {
    edition = FactoryGirl.create(:live_edition)
    web_content_item = Queries::GetWebContentItems.find(edition.id)
    link_set = FactoryGirl.create(:link_set, content_id: edition.content_id)
    FactoryGirl.create(:link, target_content_id: "d16216ce-7487-4bde-b817-ef68317fe3ab", link_set: link_set, link_type: 'taxons')
    Presenters::DownstreamPresenter.new(web_content_item, link_set, state_fallback_order: [:published])
  }

  it "mixes in the specified update_type to the presentation" do
    presentation = described_class.present(downstream_presenter, update_type: "foo")
    expect(presentation[:update_type]).to eq("foo")
  end

  it "presents the unexpanded links" do
    presentation = described_class.present(downstream_presenter, update_type: "foo")
    expect(presentation[:links]).to eq(taxons: ["d16216ce-7487-4bde-b817-ef68317fe3ab"])
  end

  it "leaves other fields intact" do
    presentation = described_class.present(downstream_presenter, update_type: "foo")
    expect(presentation).to have_key(:content_id)
    expect(presentation).to have_key(:title)
    expect(presentation).to have_key(:details)
  end
end
