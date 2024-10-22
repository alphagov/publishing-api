RSpec.describe Presenters::DetailsPresenter do
  describe ".details" do
    let(:change_history_presenter) do
      instance_double(Presenters::ChangeHistoryPresenter, change_history: [])
    end

    subject do
      described_class.new(edition, change_history_presenter).details
    end

    let(:embeddable_content) do
      create(:edition, state: "published", content_store: "live", document_type: "contact", title: "Some contact")
    end
    let(:field_value) { "{{embed:contact:#{embeddable_content.document.content_id}}}" }

    let(:edition) { create(:edition, details: edition_details, links_hash:) }
    let(:links_hash) { { embed: [embeddable_content.document.content_id] } }

    let(:presented_embed) do
      Govspeak::EmbedPresenter.new({
        content_id: embeddable_content.content_id,
        title: embeddable_content.title,
        details: embeddable_content.details,
        document_type: "contact",
      }).render
    end
    let(:expected_html) do
      "<p>#{presented_embed}</p>\n"
    end

    %w[body downtime_message more_information].each do |field_name|
      context "when we're passed a #{field_name} with embedded content" do
        context "when we're passed details with govspeak" do
          let(:edition_details) do
            {
              field_name => [
                { content_type: "text/govspeak", content: field_value },
              ],
            }
          end

          let(:expected_details) do
            {
              field_name => [
                { content_type: "text/govspeak", content: field_value },
                { content_type: "text/html", content: expected_html },
              ],
            }.symbolize_keys
          end

          it "embeds the contact details" do
            is_expected.to match(expected_details)
          end
        end

        context "when we're passed a multipart document" do
          let(:edition_details) do
            {
              parts: [
                field_name => [
                  {
                    content: field_value,
                    content_type: "text/govspeak",
                  },
                ],
                slug: "some-slug",
                title: "Some title",
              ],
            }
          end

          let(:expected_details) do
            {
              parts: [
                field_name => [
                  {
                    content: field_value,
                    content_type: "text/govspeak",
                  },
                  {
                    content: expected_html,
                    content_type: "text/html",
                  },
                ],
                slug: "some-slug",
                title: "Some title",
              ],
            }.deep_symbolize_keys
          end

          it "returns embedded content references with values from their editions" do
            is_expected.to match(expected_details)
          end
        end

        context "when the embedded content is available in multiple locales" do
          let(:edition_details) do
            {
              field_name => [
                { content_type: "text/govspeak", content: field_value },
              ],
            }
          end
          let(:embedded_document) { create(:document, content_id: embeddable_content.content_id, locale: "cy") }

          let!(:welsh_embeddable_content) do
            create(
              :edition,
              document: embedded_document,
              state: "published",
              content_store: "live",
              document_type: "contact",
              title: "WELSH",
            )
          end

          let(:expected_details) do
            {
              field_name => [
                { content_type: "text/govspeak", content: field_value },
                { content_type: "text/html", content: expected_html },
              ],
            }.symbolize_keys
          end

          context "when the edition is in the default language" do
            it "returns embedded content references with values from the same language" do
              is_expected.to match(expected_details)
            end
          end

          context "when the edition is in a non-default locale" do
            let(:presented_embed) do
              Govspeak::EmbedPresenter.new({
                content_id: welsh_embeddable_content.content_id,
                title: welsh_embeddable_content.title,
                details: welsh_embeddable_content.details,
                document_type: "contact",
              }).render
            end
            let(:edition) { create(:edition, details: edition_details, links_hash:, document: create(:document, locale: "cy")) }

            it "returns embedded content references with values from the same language" do
              is_expected.to match(expected_details)
            end
          end

          context "when the document is in an unavailable locale" do
            let(:edition) { create(:edition, details: edition_details, links_hash:, document: create(:document, locale: "fr")) }

            it "returns embedded content references with values from the default language" do
              is_expected.to match(expected_details)
            end
          end
        end

        context "when we're passed an empty array" do
          let(:edition) do
            create(:edition, details: { field_name => [] })
          end
          let(:edition_details) { edition.details }

          it "does not change anything in details" do
            is_expected.to match(edition_details)
          end
        end
      end
    end

    context "when multiple documents are embedded in different parts of the document" do
      let(:other_embeddable_content) do
        create(:edition, state: "published", content_store: "live", document_type: "contact", title: "Something else")
      end

      let(:links_hash) { { embed: [embeddable_content.document.content_id, other_embeddable_content.document.content_id] } }

      let(:edition_details) do
        {
          body: [
            { content_type: "text/govspeak", content: field_value },
          ],
          other: [
            { content_type: "text/govspeak", content: "{{embed:contact:#{other_embeddable_content.document.content_id}}}" },
          ],
        }
      end

      let(:other_presented_embed) do
        Govspeak::EmbedPresenter.new({
          content_id: other_embeddable_content.content_id,
          title: other_embeddable_content.title,
          details: other_embeddable_content.details,
          document_type: "contact",
        }).render
      end
      let(:other_expected_html) do
        "<p>#{other_presented_embed}</p>\n"
      end

      let(:expected_details) do
        {
          body: [
            { content_type: "text/govspeak", content: field_value },
            { content_type: "text/html", content: expected_html },
          ],
          other: [
            { content_type: "text/govspeak", content: "{{embed:contact:#{other_embeddable_content.document.content_id}}}" },
            { content_type: "text/html", content: other_expected_html },
          ],
        }
      end

      it "returns embedded content references with values from their editions" do
        is_expected.to match(expected_details)
      end
    end
  end
end
