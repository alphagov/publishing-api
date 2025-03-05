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

  let(:fake_content_id) { SecureRandom.uuid }

  describe "#render_embedded_content" do
    context "when the content reference does not have a corresponding live Edition" do
      context "when there is one edition that hasn't been found" do
        let(:details) { { body: "some string with a reference: {{embed:contact:#{fake_content_id}}}" } }

        it "alerts Sentry and returns the content as is" do
          expect(GovukError).to receive(:notify).with(CommandError.new(
                                                        code: 422,
                                                        message: "Could not find a live edition for embedded content ID: #{fake_content_id}",
                                                      ))
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: {{embed:contact:#{fake_content_id}}}",
          })
        end
      end
    end

    context "when there are live editions for the embedded content" do
      let(:expected_value) do
        "<span class=\"content-embed content-embed__contact\"
          data-content-block=\"\"
          data-document-type=\"contact\"
          data-content-id=\"#{embedded_content_id}\"
          data-embed-code=\"#{embed_code}\">VALUE</span>".squish
      end
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
        context "when there is a mix of existing and not existing live editions" do
          let(:details) { { body: "some string with a reference: {{embed:contact:#{embedded_content_id}}} {{embed:contact:#{fake_content_id}}}" } }

          it "alerts Sentry and returns the expected content" do
            expect(GovukError).to receive(:notify).with(CommandError.new(
                                                          code: 422,
                                                          message: "Could not find a live edition for embedded content ID: #{fake_content_id}",
                                                        ))
            expect(described_class.new(edition).render_embedded_content(details)).to eq({
              body: "some string with a reference: #{expected_value} {{embed:contact:#{fake_content_id}}}",
            })
          end
        end

        context "when there is only one embed" do
          let(:details) { { body: "some string with a reference: {{embed:contact:#{embedded_content_id}}}" } }
          it "returns embedded content references with values from their editions" do
            expect(described_class.new(edition).render_embedded_content(details)).to eq({
              body: "some string with a reference: #{expected_value}",
            })
          end
        end

        context "when there are multiple embeds" do
          context "when there are multiple embeds to the same block" do
            let(:details) { { body: "some string with a reference: #{embed_code} and another: #{embed_code}" } }
            it "returns embedded content" do
              expect(described_class.new(edition).render_embedded_content(details)).to eq({
                body: "some string with a reference: #{expected_value} and another: #{expected_value}",
              })
            end
          end

          context "when there are multiple embeds for different blocks" do
            let(:embedded_content_id_2) { SecureRandom.uuid }
            let!(:embedded_edition_2) do
              embedded_document = create(:document, content_id: embedded_content_id_2)
              create(
                :edition,
                document: embedded_document,
                state: "published",
                content_store: "live",
                document_type: "content_block_pension",
                title: "VALUE2",
              )
            end
            let(:embed_code_2) { "{{embed:content_block_pension:#{embedded_content_id_2}}}" }
            let(:links_hash) do
              {
                embed: [embedded_content_id, embedded_content_id_2],
              }
            end
            let(:expected_value_2) do
              "<span class=\"content-embed content-embed__contact\"
          data-content-block=\"\"
          data-document-type=\"contact\"
          data-content-id=\"#{embedded_content_id_2}\"
          data-embed-code=\"#{embed_code_2}\">VALUE2</span>".squish
            end
            let(:stub_block_2) { double(ContentBlockTools::ContentBlock, render: expected_value_2) }

            before do
              expect(ContentBlockTools::ContentBlock).to receive(:new).with(
                document_type: embedded_edition_2.document_type,
                content_id: embedded_edition_2.document.content_id,
                title: embedded_edition_2.title,
                details: embedded_edition_2.details,
                embed_code: embed_code_2,
              ).and_return(stub_block_2)
            end
            let(:details) { { body: "some string with a reference: #{embed_code} and another: #{embed_code_2}" } }

            it "returns embedded content" do
              expect(described_class.new(edition).render_embedded_content(details)).to eq({
                body: "some string with a reference: #{expected_value} and another: #{expected_value_2}",
              })
            end
          end
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
end
