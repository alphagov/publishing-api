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
  let(:content_id_alias) do
    create(:content_id_alias, name: "some-friendly-name", content_id: embedded_content_id)
  end
  let(:links_hash) do
    {
      embed: [embedded_content_id],
    }
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
      let(:details) { { body: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}" } }

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: "some string with a reference: VALUE",
        })
      end
    end

    context "when body is an array" do
      let(:details) do
        { body: [
          { content_type: "text/govspeak", content: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}" },
          { content_type: "text/html", content: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}" },
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

    context "when body is a hash" do
      let(:details) do
        { body: { title: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}" } }
      end

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: { title: "some string with a reference: VALUE" },
        })
      end
    end

    context "when body is a multipart document" do
      let(:details) do
        {
          parts: [
            body: [
              {
                content: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}",
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
                  content: "some string with a reference: VALUE",
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
      let(:details) { { body: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}" } }

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

    context "when the document is an email address" do
      let(:embedded_document) { create(:document) }
      let(:name) { "abc" }

      let(:links_hash) do
        {
          embed: [embedded_document.content_id],
        }
      end

      before do
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
        create(:content_id_alias, name:, content_id: embedded_document.content_id)
      end

      let(:details) { { body: "some string with a reference: {{embed:content_block_email_address:#{name}}}" } }

      it "returns an email address" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          body: "some string with a reference: foo@example.com",
        })
      end
    end

    context "when multiple documents are embedded in different parts of the document" do
      let(:other_embedded_content_id) { SecureRandom.uuid }
      let(:other_name) { "another-name" }

      before do
        embedded_document = create(:document, content_id: other_embedded_content_id)
        create(
          :edition,
          document: embedded_document,
          state: "published",
          content_store: "live",
          document_type: "contact",
          title: "VALUE2",
        )
        create(:content_id_alias, name: other_name, content_id: other_embedded_content_id)
      end

      let(:links_hash) do
        {
          embed: [embedded_content_id, other_embedded_content_id],
        }
      end

      let(:details) do
        {
          title: "title string with reference: {{embed:contact:#{other_name}}}",
          body: "some string with a reference: {{embed:contact:#{content_id_alias.name}}}",
        }
      end

      it "returns embedded content references with values from their editions" do
        expect(described_class.new(edition).render_embedded_content(details)).to eq({
          title: "title string with reference: VALUE2",
          body: "some string with a reference: VALUE",
        })
      end
    end
  end
end
