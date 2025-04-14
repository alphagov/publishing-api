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

  let!(:embedded_content_id_alias) do
    create(:content_id_alias, content_id: embedded_content_id)
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

    context "When the embed code has a UUID" do
      let(:embed_code) { "{{embed:contact:#{embedded_content_id}}}" }
      it_behaves_like "renders embedded content"
    end

    context "When the embed code has a content ID alias" do
      let(:embed_code) { "{{embed:contact:#{embedded_content_id_alias.name}}}" }
      it_behaves_like "renders embedded content"
    end
  end
end
