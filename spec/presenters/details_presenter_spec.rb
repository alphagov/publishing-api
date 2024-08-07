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

    context "when we're passed hashes rather than arrays" do
      let(:edition_details) do
        {
          body: { content_type: "text/govspeak", content: "**hello**" },
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

    context "when we're passed a body with embedded content" do
      let(:contact) do
        create(:edition, state: "published", content_store: "live", document_type: "contact", title: "Some contact")
      end
      let(:content_embed_presenter) { Presenters::ContentEmbedPresenter.new(edition) }
      let(:body) { "{{embed:contact:#{contact.document.content_id}}}" }

      context "when the body is not enumerable" do
        let(:edition) { create(:edition, details: { body: }, links_hash: { embed: [contact.document.content_id] }) }
        let(:edition_details) { edition.details }
        let(:expected_details) do
          {
            body: contact.title,
          }
        end

        it "embeds the contact details" do
          is_expected.to match(expected_details)
        end
      end

      context "when we're passed details with govspeak and HTML" do
        let(:edition) do
          create(:edition,
                 details: { body: [
                   { content_type: "text/html", content: body },
                   { content_type: "text/govspeak", content: body },
                 ] },
                 links_hash: { embed: [contact.document.content_id] })
        end
        let(:edition_details) { edition.details }
        let(:expected_details) do
          {
            body: [
              { content_type: "text/html", content: contact.title },
              { content_type: "text/govspeak", content: contact.title },
            ],
          }
        end

        it "embeds the contact details" do
          is_expected.to match(expected_details)
        end
      end

      context "when we're passed an empty array" do
        let(:edition) do
          create(:edition, details: { body: [] })
        end
        let(:edition_details) { edition.details }

        it "does not change anything in details" do
          is_expected.to match(edition_details)
        end
      end
    end
  end
end
