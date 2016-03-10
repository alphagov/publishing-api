require 'rails_helper'

RSpec.describe Pagination do
  describe 'initialize' do
    context "with a start option" do
      subject { described_class.new(start: "5") }

      it "parses the start option as an integer" do
        expect(subject.start).to eq(5)
      end

      it "returns the default page_size" do
        expect(subject.page_size).to eq(50)
      end
    end

    context "with a page_size option" do
      subject { described_class.new(page_size: "20") }

      it "parses the page_size option as an integer" do
        expect(subject.page_size).to eq(20)
      end

      it "returns the default start" do
        expect(subject.start).to eq(0)
      end
    end

    context "with pagination option" do
      subject { described_class.new(start: "5", page_size: "20") }

      it "parses the start option as an integer" do
        expect(subject.start).to eq(5)
      end

      it "parses the page_size option as an integer" do
        expect(subject.page_size).to eq(20)
      end
    end

    context "default order option" do
      subject { described_class.new }

      it "uses the default order" do
        expect(subject.order).to eq(public_updated_at: :desc)
      end
    end

    context "with page option" do
      subject(:pagination) { described_class.new(page: 2) }

      it "set the offset to 0" do
        expect(pagination.start).to eq(50)
      end
    end
  end
end
