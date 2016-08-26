require 'rails_helper'

RSpec.describe Presenters::Queries::LinkablePresenter do
  let(:internal_name) { nil }
  let(:state) { "draft" }
  let(:date) { Time.now.utc.iso8601 }

  let(:args) {
    [
      SecureRandom.uuid,
      state,
      "A title",
      "/vat-rates",
      date,
      date,
      internal_name,
    ]
  }

  describe ".present" do
    context "when internal_name is missing" do
      it "uses the title" do
        output = described_class.present(*args)
        expect(output[:internal_name]).to eq("A title")
      end
    end

    context "when internal_name is present" do
      let(:internal_name) { "An internal name" }

      it "uses the internal_name" do
        output = described_class.present(*args)
        expect(output[:internal_name]).to eq("An internal name")
      end
    end

    context "when state is not 'published'" do
      it "uses the state" do
        output = described_class.present(*args)
        expect(output[:publication_state]).to eq("draft")
      end
    end

    context "when state is 'published'" do
      let(:state) { "published" }

      it "shows as 'published'" do
        output = described_class.present(*args)
        expect(output[:publication_state]).to eq("published")
      end
    end

    context 'when updated_at is passed' do
      it 'shows updated_at datetime' do
        output = described_class.present(*args)
        expect(output[:updated_at]).to eq(date)
      end
    end

    context 'when created_at is passed' do
      it 'shows created_at datetime' do
        output = described_class.present(*args)
        expect(output[:created_at]).to eq(date)
      end
    end
  end
end
