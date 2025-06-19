RSpec.describe Presenters::DetailsPresenter do
  describe ".details" do
    let(:change_history_presenter) do
      instance_double(Presenters::ChangeHistoryPresenter, change_history: [])
    end

    let(:content_embed_presenter) do
      instance_double(Presenters::ContentEmbedPresenter, render_embedded_content: nil)
    end

    subject do
      described_class.new(edition_details, change_history_presenter, content_embed_presenter).details
    end

    context "when we're passed details without a body" do
      let(:edition_details) { {} }

      it "matches original details" do
        is_expected.to match(edition_details)
      end
    end

    context "without a change history presenter" do
      let(:change_history_presenter) { nil }
      let(:edition_details) do
        { body: "Without change history" }
      end

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
            { content_type: "text/govspeak", content: "<b>html</b>" },
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

      let(:expected_result) do
        {
          body: [
            { content_type: "text/govspeak", content: "**hello**" },
            { content_type: "text/html", content: "<p><strong>hello</strong></p>\n" },
          ],
        }
      end

      it { is_expected.to match(expected_result) }
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
            { content_type: "text/html", content: "<p><strong>hello</strong></p>\n" },
          ],
          other: [
            { content_type: "text/govspeak", content: "**goodbye**" },
            { content_type: "text/html", content: "<p><strong>goodbye</strong></p>\n" },
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
        it "passes the specified locale to Govspeak" do
          expect(Govspeak::Document)
            .to receive(:new)
            .with(anything, a_hash_including(locale: "cy"))
            .and_call_original

          described_class.new(
            edition_details,
            change_history_presenter,
            content_embed_presenter,
            locale: "cy",
          ).details
        end

        context "when the provided locale is nil" do
          it "passes English as the locale to Govspeak" do
            expect(Govspeak::Document)
              .to receive(:new)
              .with(anything, a_hash_including(locale: "en"))
              .and_call_original

            described_class.new(
              edition_details,
              change_history_presenter,
              content_embed_presenter,
              locale: nil,
            ).details
          end
        end
      end
    end

    %w[body downtime_message more_information].each do |field_name|
      context "when we're passed a #{field_name} with embedded content" do
        let(:embeddable_content) do
          create(:edition, state: "published", content_store: "live", document_type: "content_block_contact", title: "Some contact")
        end
        let(:content_embed_presenter) { Presenters::ContentEmbedPresenter.new(edition) }
        let(:field_value) { "{{embed:content_block_contact:#{embeddable_content.document.content_id}}}" }

        context "when the #{field_name} is not enumerable" do
          let(:edition) { create(:edition, details: { field_name => field_value }, links_hash: { embed: [embeddable_content.document.content_id] }) }
          let(:edition_details) { edition.details }
          let(:expected_details) do
            {
              field_name => presented_details_for(embeddable_content, field_value),
            }.symbolize_keys
          end

          it "embeds the contact details" do
            is_expected.to match(expected_details)
          end

          context "when the embed code contains an alias" do
            let(:content_id_alias) do
              create(:content_id_alias, name: "a-friendly-name", content_id: embeddable_content.document.content_id)
            end
            let(:field_value) { "{{embed:content_block_contact:#{content_id_alias.name}}}" }

            it "embeds the contact details" do
              is_expected.to match(expected_details)
            end
          end
        end

        context "when we're passed details with govspeak and HTML" do
          let(:edition) do
            create(:edition,
                   details: { field_name => [
                     { content_type: "text/html", content: field_value },
                     { content_type: "text/govspeak", content: field_value },
                   ] },
                   links_hash: { embed: [embeddable_content.document.content_id] })
          end
          let(:edition_details) { edition.details }
          let(:expected_details) do
            {
              field_name => [
                { content_type: "text/html", content: presented_details_for(embeddable_content, field_value) },
                { content_type: "text/govspeak", content: presented_details_for(embeddable_content, field_value) },
              ],
            }.symbolize_keys
          end

          it "embeds the contact details" do
            is_expected.to match(expected_details)
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
  end
end
