require 'rails_helper'

RSpec.describe Pagination do
  describe 'initialize' do
    context "without pagination params" do
      subject { described_class.new}

      it "returns all items" do
        expect(subject.all_items).to be(true)
      end
    end

    context "with a start param" do
      subject { described_class.new(start: "5") }

      it "parses the start param as an integer" do
        expect(subject.start).to eq(5)
      end
      it "returns the default page_size" do
        expect(subject.page_size).to eq(50)
      end
    end

  context "with a page_size param" do
    subject { described_class.new(page_size: "20")}

      it "parses the page_size param as an integer" do
        expect(subject.page_size).to eq(20)
      end
      it "returns the default start" do
        expect(subject.start).to eq(0)
      end
    end
  end

  context "with pagination params" do
    subject { described_class.new(start: "5", page_size: "20")}

    it "parses the start param as an integer" do
      expect(subject.start).to eq(5)
    end
    it "parses the page_size param as an integer" do
      expect(subject.page_size).to eq(20)
    end
  end
end
