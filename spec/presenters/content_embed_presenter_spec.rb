RSpec.describe Presenters::ContentEmbedPresenter do
  let(:embedded_content_id) { SecureRandom.uuid }
  let(:embed_code) { "{{embed:contact:#{embedded_content_id}}}" }
  let(:document) { create(:document) }
  let(:edition) do
    create(
      :edition,
      document:,
      details: details.deep_stringify_keys,
      links_hash:,
    )
  end
  let(:links_hash) do
    {
      embed: [embedded_content_id],
    }
  end
  let(:details) { {} }

  let!(:embedded_edition) do
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
    let(:expected_value) { "VALUE" }
    let(:stub_block) { double(ContentBlockTools::ContentBlock, render: expected_value) }

    before do
      expect(ContentBlockTools::ContentBlock).to receive(:new).with(
        document_type: embedded_edition.document_type,
        content_id: embedded_edition.document.content_id,
        title: embedded_edition.title,
        details: embedded_edition.details,
        embed_code: embed_code,
      ).at_least(:once).and_return(stub_block)
    end

    context "when body is a string" do
      let(:details) { { body: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" } }

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: "some string with a reference: #{expected_value}",
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
            { content_type: "text/govspeak", content: "some string with a reference: #{expected_value}" },
            { content_type: "text/html", content: "some string with a reference: #{expected_value}" },
          ],
        })
      end
    end

    context "when body is a hash" do
      let(:details) do
        { body: { title: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" } }
      end

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: { title: "some string with a reference: #{expected_value}" },
        })
      end
    end

    context "when body is a multipart document" do
      let(:details) do
        {
          parts: [
            body: [
              {
                content: "some string with a reference: {{embed:contact:#{embedded_content_id}}}",
                content_type: "text/govspeak",
              },
            ],
            slug: "some-slug",
            title: "Some title",
          ],
        }
      end

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq(
          {
            parts: [
              body: [
                {
                  content: "some string with a reference: #{expected_value}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-slug",
              title: "Some title",
            ],
          },
        )
      end
    end

    context "when the embedded content is available in multiple locales" do
      let(:details) { { body: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" } }

      let!(:welsh_edition) do
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
            body: "some string with a reference: #{expected_value}",
          })
        end
      end

      context "when the document is in an available locale" do
        let(:document) { create(:document, locale: "cy") }
        let(:embedded_edition) { welsh_edition }

        it "returns embedded content references with values from the same language" do
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: #{expected_value}",
          })
        end
      end

      context "when the document is in an unavailable locale" do
        let(:document) { create(:document, locale: "fr") }

        it "returns embedded content references with values from the default language" do
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: #{expected_value}",
          })
        end
      end
    end

    context "when multiple documents are embedded in different parts of the document" do
      let(:other_embedded_content_id) { SecureRandom.uuid }
      let(:other_embed_code) { "{{embed:contact:#{other_embedded_content_id}}}" }

      let!(:other_embedded_edition) do
        embedded_document = create(:document, content_id: other_embedded_content_id)
        create(
          :edition,
          document: embedded_document,
          state: "published",
          content_store: "live",
          document_type: "contact",
          title: "VALUE2",
        )
      end

      let(:other_expected_value) { "VALUE2" }
      let(:other_stub_block) { double(ContentBlockTools::ContentBlock, render: other_expected_value) }

      before do
        expect(ContentBlockTools::ContentBlock).to receive(:new).with(
          document_type: other_embedded_edition.document_type,
          content_id: other_embedded_edition.document.content_id,
          title: other_embedded_edition.title,
          details: other_embedded_edition.details,
          embed_code: other_embed_code,
        ).at_least(:once).and_return(other_stub_block)
      end

      let(:links_hash) do
        {
          embed: [embedded_content_id, other_embedded_content_id],
        }
      end

      let(:details) do
        {
          title: "title string with reference: {{embed:contact:#{other_embedded_content_id}}}",
          body: "some string with a reference: {{embed:contact:#{embedded_content_id}}}",
        }
      end

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          title: "title string with reference: #{other_expected_value}",
          body: "some string with a reference: #{expected_value}",
        })
      end
    end
  end
end
