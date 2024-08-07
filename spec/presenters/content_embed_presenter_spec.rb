RSpec.describe Presenters::ContentEmbedPresenter do
  let(:embedded_content_id) { SecureRandom.uuid }
  let(:document) { create(:document) }
  let(:edition) do
    create(
      :edition,
      document:,
      details: details.deep_stringify_keys,
      links_hash: {
        embed: [embedded_content_id],
      },
    )
  end
  let(:details) { {} }

  before do
    embedded_document = create(:document, content_id: embedded_content_id)
    create(
      :edition,
      document: embedded_document,
      state: "published",
      content_store: "live",
      document_type: "contact",
      title: "VALUE",
    )
  end

  describe "#render_embedded_content" do
    context "when body is a string" do
      let(:details) { { body: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" } }

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: "some string with a reference: VALUE",
        })
      end
    end

    context "when body is an array" do
      let(:details) do
        { body: [
          { content_type: "text/govspeak", content: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" },
          { content_type: "text/html", content: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" },
        ] }
      end

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: [
            { content_type: "text/govspeak", content: "some string with a reference: VALUE" },
            { content_type: "text/html", content: "some string with a reference: VALUE" },
          ],
        })
      end
    end

    context "when the embedded content is available in multiple locales" do
      let(:details) { { body: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" } }

      before do
        embedded_document = create(:document, content_id: embedded_content_id, locale: "cy")
        create(
          :edition,
          document: embedded_document,
          state: "published",
          content_store: "live",
          document_type: "contact",
          title: "WELSH",
        )
      end

      context "when the document is in the default language" do
        it "returns embedded content references with values from the same language" do
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: VALUE",
          })
        end
      end

      context "when the document is in an available locale" do
        let(:document) { create(:document, locale: "cy") }

        it "returns embedded content references with values from the same language" do
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: WELSH",
          })
        end
      end

      context "when the document is in an unavailable locale" do
        let(:document) { create(:document, locale: "fr") }

        it "returns embedded content references with values from the default language" do
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: VALUE",
          })
        end
      end
    end
  end
end
