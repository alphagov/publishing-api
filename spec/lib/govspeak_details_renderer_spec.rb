RSpec.describe GovspeakDetailsRenderer do
  let(:locale) { "en" }

  subject do
    described_class.new(edition_details, locale:).render
  end

  context "when we're passed details without a body" do
    let(:edition_details) { {} }

    it "matches original details" do
      is_expected.to match(edition_details)
    end
  end

  context "when we're passed a body which isn't enumerable" do
    let(:edition_details) do
      {
        body: "Something about VAT",
      }
    end

    it "matches original details" do
      is_expected.to match(edition_details)
    end
  end
  context "when we're passed details with govspeak and HTML" do
    let(:edition_details) do
      {
        body: [
          { content_type: "text/html", content: "<b>html</b>" },
          { content_type: "text/govspeak", content: "**html**" },
        ],
      }
    end

    it "matches original details" do
      is_expected.to match(edition_details)
    end
  end

  context "when we're passed govspeak without HTML" do
    let(:edition_details) do
      {
        body: [
          { content_type: "text/govspeak", content: "**hello**" },
        ],
      }
    end

    it "should render the HTML as text/html and include rendered_by: publishing-api" do
      expect(subject[:body]).to contain_exactly(
        hash_including(content_type: "text/govspeak"),
        hash_including(
          content_type: "text/html",
          content: a_string_starting_with("<p>"),
          rendered_by: "publishing-api",
        ),
      )
    end
  end

  context "when we're passed multiple govspeak fields" do
    let(:edition_details) do
      {
        body: [
          { content_type: "text/govspeak", content: "**hello**" },
        ],
        other: [
          { content_type: "text/govspeak", content: "**goodbye**" },
        ],

      }
    end

    let(:expected_result) do
      {
        body: [
          { content_type: "text/govspeak", content: "**hello**" },
          {
            content_type: "text/html",
            content: "<p><strong>hello</strong></p>\n",
            rendered_by: "publishing-api",
          },
        ],
        other: [
          { content_type: "text/govspeak", content: "**goodbye**" },
          {
            content_type: "text/html",
            content: "<p><strong>goodbye</strong></p>\n",
            rendered_by: "publishing-api",
          },
        ],
      }
    end

    it { is_expected.to match(expected_result) }
  end

  context "when we're passed an image hash" do
    let(:edition_details) do
      { image: { content_type: "image/png", content: "some content" } }
    end

    it "doesn't wrap the hash in an array" do
      expect(subject).to eq edition_details
    end
  end

  context "value contains nested array" do
    let(:edition_details) { { other: %w[an array of strings] } }
    it "doesn't try to convert to govspeak" do
      expect { subject }.to_not raise_error
    end
  end

  context "when we're passed a deeply-nested hash with govspeak" do
    let(:edition_details) do
      {
        parts: [
          {
            body: [
              {
                content_type: "text/govspeak",
                content: "foo",
              },
            ],
          },
        ],
      }
    end

    let(:expected_details) do
      {
        parts: [
          {
            body: [
              {
                content_type: "text/govspeak",
                content: "foo",
              },
              {
                content_type: "text/html",
                content: "<p>foo</p>\n",
                rendered_by: "publishing-api",
              },
            ],
          },
        ],
      }
    end

    it "converts from govspeak appropriately" do
      expect(subject).to eq expected_details
    end
  end

  describe "providing a locale to Govspeak" do
    let(:edition_details) do
      {
        body: [
          { content_type: "text/govspeak", content: "**hello**" },
        ],
      }
    end

    context "when we're passed Govspeak without a locale specified" do
      it "passes English as the locale to Govspeak" do
        expect(Govspeak::Document)
          .to receive(:new)
          .with(anything, a_hash_including(locale: "en"))
          .and_call_original

        subject
      end
    end

    context "when we're passed Govspeak with a locale specified" do
      let(:locale) { "cy" }

      it "passes the specified locale to Govspeak" do
        expect(Govspeak::Document)
          .to receive(:new)
          .with(anything, a_hash_including(locale: "cy"))
          .and_call_original

        subject
      end

      context "when the provided locale is nil" do
        let(:locale) { nil }

        it "passes English as the locale to Govspeak" do
          expect(Govspeak::Document)
            .to receive(:new)
            .with(anything, a_hash_including(locale: "en"))
            .and_call_original

          subject
        end
      end
    end
  end

  describe "removing content rendered by publishing-api" do
    it "removes content rendered by publishing-api" do
      details = {
        body: [
          { content_type: "text/govspeak", content: "blah" },
          { content_type: "text/html", content: "blah", rendered_by: "publishing-api" },
        ],
      }
      result = described_class.new(details).remove_content_rendered_by_publishing_api
      expect(result[:body]).to match_array([{ content_type: "text/govspeak", content: "blah" }])
    end

    it "removes nested content rendered by publishing-api" do
      details = {
        parts: [
          {
            body: [
              { content_type: "text/govspeak", content: "blah" },
              { content_type: "text/html", content: "blah", rendered_by: "publishing-api" },
            ],
          },
        ],
      }
      result = described_class.new(details).remove_content_rendered_by_publishing_api
      expect(result.dig(:parts, 0, :body)).to match_array([{ content_type: "text/govspeak", content: "blah" }])
    end

    it "retains content not rendered by publishing-api" do
      details = {
        body: [
          { content_type: "text/govspeak", content: "blah" },
          { content_type: "text/html", content: "blah", rendered_by: "something else!" },
        ],
      }
      result = described_class.new(details).remove_content_rendered_by_publishing_api
      expect(result[:body]).to match_array([
        { content_type: "text/govspeak", content: "blah" },
        { content_type: "text/html", content: "blah", rendered_by: "something else!" },
      ])
    end
  end
end
