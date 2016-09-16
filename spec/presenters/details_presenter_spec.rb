require "rails_helper"

RSpec.describe Presenters::DetailsPresenter do
  describe ".details" do
    subject { described_class.new(content_item_details).details }

    context "when we're passed details without a body" do
      let(:content_item_details) { {} }

      it "matches original details" do
        is_expected.to match(content_item_details)
      end
    end

    context "when we're passed a body which isn't enumerable" do
      let(:content_item_details) do
        {
          body: "Something about VAT"
        }
      end

      it "matches original details" do
        is_expected.to match(content_item_details)
      end
    end

    context "when we're passed details with govspeak and HTML" do
      let(:content_item_details) do
        {
          body: [
            { content_type: "text/html", content: "<b>html</b>" },
            { content_type: "text/govspeak", content: "<b>html</b>" }
          ]
        }
      end

      it "matches original details" do
        is_expected.to match(content_item_details)
      end
    end

    context "when we're passed govspeak without HTML" do
      let(:content_item_details) do
        {
          body: [
            { content_type: "text/govspeak", content: "**hello**" }
          ]
        }
      end

      let(:expected_result) do
        {
          body: [
            { content_type: "text/govspeak", content: "**hello**" },
            { content_type: "text/html", content: "<p><strong>hello</strong></p>\n" }
          ]
        }
      end

      it { is_expected.to match(expected_result) }
    end

    context "when we're passed multiple govspeak fields" do
      let(:content_item_details) do
        {
          body: [
            { content_type: "text/govspeak", content: "**hello**" }
          ],
          other: [
            { content_type: "text/govspeak", content: "**goodbye**" }
          ],

        }
      end

      let(:expected_result) do
        {
          body: [
            { content_type: "text/govspeak", content: "**hello**" },
            { content_type: "text/html", content: "<p><strong>hello</strong></p>\n" }
          ],
          other: [
            { content_type: "text/govspeak", content: "**goodbye**" },
            { content_type: "text/html", content: "<p><strong>goodbye</strong></p>\n" }
          ],
        }
      end

      it { is_expected.to match(expected_result) }
    end
  end
end
