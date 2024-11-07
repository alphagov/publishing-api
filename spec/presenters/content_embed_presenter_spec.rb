RSpec.describe Presenters::ContentEmbedPresenter do
  let(:embedded_content_id) { SecureRandom.uuid }
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
    let(:expected_value) { Presenters::ContentEmbed::BasePresenter.new(embedded_edition).render }

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
        let(:expected_value) { Presenters::ContentEmbed::BasePresenter.new(welsh_edition).render }

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

    context "when the document is an email address" do
      let(:embedded_document) { create(:document) }
      let(:links_hash) do
        {
          embed: [embedded_document.content_id],
        }
      end

      let!(:embedded_edition) do
        create(
          :edition,
          document: embedded_document,
          state: "published",
          content_store: "live",
          document_type: "content_block_email_address",
          details: {
            email_address: "foo@example.com",
          },
        )
      end

      let(:details) { { body: "some string with a reference: {{embed:content_block_email_address:#{embedded_document.content_id}}}" } }
      let(:expected_value) { Presenters::ContentEmbed::EmailAddressPresenter.new(embedded_edition).render }

      it "returns an email address" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: "some string with a reference: #{expected_value}",
        })
      end
    end

    context "when multiple documents are embedded in different parts of the document" do
      let(:other_embedded_content_id) { SecureRandom.uuid }

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
      let(:other_expected_value) { Presenters::ContentEmbed::BasePresenter.new(other_embedded_edition).render }

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
