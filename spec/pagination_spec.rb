require 'rails_helper'

RSpec.describe Pagination do
  describe "initialize" do
    context "without pagination params" do
      subject { described_class.new }

      it "returns the default start value" do
        expect(subject.start).to eq(0)
      end
    end

    context "with a start param" do
      subject { described_class.new(start: "5") }

      it "parses the start param as an integer" do
        expect(subject.start).to eq(5)
      end
      it "returns the default count" do
        expect(subject.count).to eq(50)
      end
    end


    context "with a count param" do
      subject { described_class.new(count: "20") }

      it "parses the count param as an integer" do
        expect(subject.count).to eq(20)
      end
      it "returns the default start" do
        expect(subject.start).to eq(0)
      end
    end


    context "with pagination params" do
      subject { described_class.new(start: "5", count: "20") }

      it "parses the start param as an integer" do
        expect(subject.start).to eq(5)
      end
      it "parses the count param as an integer" do
        expect(subject.count).to eq(20)
      end
    end
  end
end
