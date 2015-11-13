require 'rails_helper'

RSpec.describe Presenters::Queries::ContentItemPresenter do
  describe "present" do
    let(:content_id) { SecureRandom.uuid }

    before do
      content_item = FactoryGirl.create(:draft_content_item, content_id: content_id)
      FactoryGirl.create(:version, target: content_item, number: 101)
      @result = Presenters::Queries::ContentItemPresenter.present(content_item)
    end

    it "presents content item attributes as a hash" do
      expect(@result.fetch(:content_id)).to eq(content_id)
    end

    it "exposes the version number of the content item" do
      expect(@result.fetch(:version)).to eq(101)
    end

    it "exposes the publication state of the content item" do
      expect(@result.fetch(:publication_state)).to eq("draft")
    end
  end
end
