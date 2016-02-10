require "rails_helper"

RSpec.describe Location do
  describe "validations" do
    context "#base_path" do
      it "should be an absolute path" do
        subject.base_path = 'invalid//absolute/path/'
        expect(subject).to be_invalid
        expect(subject.errors[:base_path].size).to eq(1)
      end
    end
  end

  describe "routes and redirects" do
    subject { FactoryGirl.build(:location) }
    let(:content_item) { FactoryGirl.build(:content_item) }

    before do
      subject.content_item = content_item
    end

    it_behaves_like RoutesAndRedirectsValidator
  end
end
