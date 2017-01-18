require "rails_helper"

RSpec.describe Presenters::DebugPresenter do
  let(:document) { FactoryGirl.create(:document) }
  let!(:content_item) { FactoryGirl.create(:content_item, document: document) }

  subject do
    described_class.new(document.content_id)
  end

  describe ".title" do
    it "matches" do
      expect(subject.title).to match("VAT rates")
    end
  end
end
