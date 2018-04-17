require 'rails_helper'

RSpec.describe Pagination do
  describe 'initialize' do
    context "with a offset option" do
      subject { described_class.new(offset: "5") }

      it "parses the offset option as an integer" do
        expect(subject.offset).to eq(5)
      end

      it "returns the default per_page" do
        expect(subject.per_page).to eq(50)
      end
    end

    context "with a per_page option" do
      subject { described_class.new(per_page: "20") }

      it "parses the per_page option as an integer" do
        expect(subject.per_page).to eq(20)
      end

      it "returns the default offset" do
        expect(subject.offset).to eq(0)
      end
    end

    context "with pagination option" do
      subject { described_class.new(offset: "5", per_page: "20") }

      it "parses the offset option as an integer" do
        expect(subject.offset).to eq(5)
      end

      it "parses the per_page option as an integer" do
        expect(subject.per_page).to eq(20)
      end
    end

    context "default order option" do
      subject { described_class.new }

      it "uses the default order" do
        expect(subject.order).to eq([%i[public_updated_at desc]])
      end
    end

    context "with page option" do
      subject(:pagination) { described_class.new(page: 2, per_page: 20) }

      it "set the offset to 0" do
        expect(pagination.offset).to eq(20)
      end
    end

    context "pages" do
      let(:total) { 19 }
      subject(:pagination) { described_class.new(page: 2, per_page: 20) }

      it "calculats the total number of pages" do
        expect(pagination.pages(total)).to eq(1)
      end
    end
  end
end
