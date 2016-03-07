require 'rails_helper'

RSpec.describe Pagination do
  describe 'initialize' do
    context "without pagination params" do
      subject { described_class.new }

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
      subject { described_class.new(page_size: "20") }

      it "parses the page_size param as an integer" do
        expect(subject.page_size).to eq(20)
      end

      it "returns the default start" do
        expect(subject.start).to eq(0)
      end
    end

    context "with pagination params" do
      subject { described_class.new(start: "5", page_size: "20") }

      it "parses the start param as an integer" do
        expect(subject.start).to eq(5)
      end

      it "parses the page_size param as an integer" do
        expect(subject.page_size).to eq(20)
      end
    end

    context "default order param" do
      subject { described_class.new }

      it "uses the default order" do
        expect(subject.order).to eq(public_updated_at: :desc)
      end
    end
  end

  describe "paginate" do
    let(:items) { double(:items) }
    let(:scope) { double(:scope) }

    context "when all items are requested" do
      it "doesn't apply limiting or offset to the scope" do
        expect(items).not_to receive(:limit)
        expect(described_class.new.paginate(items)).to eq(items)
      end
    end

    context "using default pagination page size" do
      it "applies a default limit and offset to the scope" do
        expect(scope).to receive(:offset).with(33)
        expect(items).to receive(:limit).with(50).and_return(scope)

        described_class.new(start: "33").paginate(items)
      end
    end

    context "using default pagination offset" do
      it "applies a default offset to the scope" do
        expect(scope).to receive(:offset).with(0)
        expect(items).to receive(:limit).with(40).and_return(scope)

        described_class.new(page_size: "40").paginate(items)
      end
    end

    context "using pagination offset and page size" do
      it "applies offset and page size to the scope" do
        expect(scope).to receive(:offset).with(20)
        expect(items).to receive(:limit).with(40).and_return(scope)

        described_class.new(start: "20", page_size: "40").paginate(items)
      end
    end
  end
end
