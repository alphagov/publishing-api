require "rails_helper"

RSpec.describe Location do
  describe "validations" do
    subject { FactoryGirl.build(:location) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end

  describe "routes and redirects" do
    subject { FactoryGirl.build(:location) }
    let(:content_item) { FactoryGirl.build(:content_item, base_path: "/vat-rates") }

    before do
      subject.content_item = content_item
    end

    it_behaves_like RoutesAndRedirectsValidator
  end
end
