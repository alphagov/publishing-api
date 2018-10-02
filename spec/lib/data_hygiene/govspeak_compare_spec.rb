require 'rails_helper'

RSpec.describe DataHygiene::GovspeakCompare do
  let(:edition) { create(:edition, details: details) }
  let(:details) do
    { body: [
        { content_type: "text/html", content: body_html },
        { content_type: "text/govspeak", content: body_govspeak },
      ],
      other: [
        { content_type: "text/html", content: other_html },
        { content_type: "text/govspeak", content: other_govspeak },
      ],}
  end

  let(:body_html) { "<h1>Foo</h1>" }
  let(:body_govspeak) { "#Foo" }
  let(:other_html) { body_html }
  let(:other_govspeak) { body_govspeak }

  describe '.published_html' do
    subject { described_class.new(edition).published_html }

    context "when details is an empty hash" do
      let(:details) { {} }
      it { is_expected.to be_a Hash }
      it { is_expected.to be_empty }
    end

    context "when there are two fields with content_type HTML and one with only govspeak" do
      let(:details) do
        { field_1: { content_type: "text/html", content: "<h1>Hi</h1>" },
          field_2: [
            { content_type: "text/html", content: "<h1>Hello</h1>" },
            { content_type: "text/govspeak", content: "#Hi" },
          ],
          field_3: [{ content_type: "text/govspeak", content: "#Erm" }],}
      end
      it { is_expected.to include(:field_1, :field_2) }
    end

    context "when the HTML includes aspects that Nokogiri changes" do
      let(:body_html) do
        "<p>HTML entities: &pound; <br /> Unicode characters: &#x1f355;"
      end
      let(:expected_html) do
        "<p>HTML entities: £ <br> Unicode characters: 🍕</p>"
      end
      it { is_expected.to include(body: expected_html) }
    end
  end

  describe '.generated_html' do
    subject { described_class.new(edition).generated_html }

    context "when details is an empty hash" do
      let(:details) { {} }
      it { is_expected.to be_a Hash }
      it { is_expected.to be_empty }
    end

    context "when details contains govspeak fields" do
      let(:details) do
        { field_1: { content_type: "text/html", content: "<h1>Hi</h1>" },
          field_2: [
            { content_type: "text/html", content: "<h1>Hello</h1>" },
            { content_type: "text/govspeak", content: "#Hi" },
          ],
          field_3: [{ content_type: "text/govspeak", content: "Erm" }],}
      end

      it { is_expected.to include(:field_2, :field_3) }
      it { is_expected.to include(field_2: %{<h1 id="hi">Hi</h1>\n}) }
      it { is_expected.to include(field_3: "<p>Erm</p>\n") }
    end
  end

  describe '.diffs' do
    subject { described_class.new(edition).diffs }

    context "when published_html is the same as generated_html" do
      let(:body_html) { "<p>Hello World</p>\n" }
      let(:body_govspeak) { "Hello World" }
      let(:expected) { { body: [], other: [] } }

      it "has an empty array for each html field" do
        is_expected.to eq expected
      end
    end

    context "when a HTML field is missing" do
      let(:html) { "<p>Hi</p>\n" }
      let(:details) do
        { field_1: { content_type: "text/govspeak", content: "Hi" } }
      end

      it { is_expected.to include(field_1: ["+#{html}"]) }
    end

    context "when the HTML is different" do
      let(:body_html) { "<p>Hi</p>\n" }
      let(:body_govspeak) { "Hello\n" }

      it { is_expected.to include(body: ["-#{body_html}", "+<p>Hello</p>\n"]) }
    end

    context "when there is extra white space in the HTML" do
      let(:body_html) { "<p>  Whitespace   </p>\n" }
      let(:body_govspeak) { "Whitespace\n" }

      it { is_expected.to include(body: []) }
    end

    context "when there are extra new lines in the HTML" do
      let(:body_html) { "<p>Foo</p>\n\n\n\n\n<p>Bar</p>\n" }
      let(:body_govspeak) { "Foo\n\nBar\n" }

      it { is_expected.to include(body: []) }
    end

    context "when the govspeak wraps inline attachments in spans" do
      let(:body_html) { %{<p><a href="url">Inline Attachment</a></p>\n} }
      let(:body_govspeak) do
        %{<span class="attachment-inline"><a href="url">Inline Attachment</a></span>\n}
      end

      it { is_expected.to include(body: []) }
    end

    context "when the govspeak contains rel=\"external\"" do
      let(:body_html) { %{<p><a href="url" rel="external">My File</a></p>\n} }
      let(:body_govspeak) do
        %{<a href="url">My File</a>\n}
      end

      it { is_expected.to include(body: []) }
    end
  end

  describe 'same_html?' do
    subject { described_class.new(edition).same_html? }

    context "when govspeak will render to the same HTML" do
      let(:body_html) { "<p>Foo</p>\n" }
      let(:body_govspeak) { "Foo\n" }

      it { is_expected.to be true }
    end

    context "when the govspeak will render to a diff we'd ignore" do
      let(:body_html) { "<p> Foo </p>\n" }
      let(:body_govspeak) { "Foo\n" }

      it { is_expected.to be false }
    end

    context "when there is no HTML to compare" do
      let(:details) { {} }
      it { is_expected.to be true }
    end
  end

  describe 'pretty_much_same_html?' do
    subject { described_class.new(edition).pretty_much_same_html? }

    context "when govspeak will render to the same HTML" do
      let(:body_html) { "<p>Foo</p>\n" }
      let(:body_govspeak) { "Foo\n" }

      it { is_expected.to be true }
    end

    context "when the govspeak will render to a diff we'd ignore" do
      let(:body_html) { "<p> Foo </p>\n" }
      let(:body_govspeak) { "Foo\n" }

      it { is_expected.to be true }
    end

    context "when the govspeak will render to a diff we'd acknowledge" do
      let(:body_html) { "<p>Foo</p>\n" }
      let(:body_govspeak) { "Bar\n" }

      it { is_expected.to be false }
    end

    context "when there is no HTML to compare" do
      let(:details) { {} }
      it { is_expected.to be true }
    end
  end
end
