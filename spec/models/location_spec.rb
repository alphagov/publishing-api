require "rails_helper"

RSpec.describe Location do
  describe "validations" do
    subject { FactoryGirl.build(:location) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    context "#base_path" do
      it "should be an absolute path" do
        subject.base_path = 'invalid//absolute/path/'
        expect(subject).to be_invalid
        expect(subject.errors[:base_path].size).to eq(1)
      end
    end

    context "when another content item has identical supporting objects" do
      before do
        FactoryGirl.create(:content_item, base_path: "/foo")
      end

      let(:content_item) do
        FactoryGirl.create(:content_item, base_path: "/bar")
      end

      subject {
        FactoryGirl.build(:location, content_item: content_item, base_path: "/foo")
      }

      it "is invalid" do
        expect(subject).to be_invalid

        error = subject.errors[:content_item].first
        expect(error).to match(/conflicts with/)
      end
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

  describe ".filter" do
    let!(:vat_item) do
      FactoryGirl.create(
        :content_item,
        title: "VAT Title",
        base_path: "/vat-rates",
      )
    end

    let!(:tax_item) do
      FactoryGirl.create(
        :content_item,
        title: "Tax Title",
        base_path: "/tax",
      )
    end

    it "filters a content item scope by state name" do
      vat_items = described_class.filter(ContentItem.all, base_path: "/vat-rates")
      expect(vat_items.pluck(:title)).to eq(["VAT Title"])

      tax_items = described_class.filter(ContentItem.all, base_path: "/tax")
      expect(tax_items.pluck(:title)).to eq(["Tax Title"])
    end
  end
end
