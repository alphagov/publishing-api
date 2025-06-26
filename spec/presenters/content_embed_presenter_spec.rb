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
      document_type: "content_block_contact",
      title: "VALUE",
    )
  end

  let!(:embedded_content_id_alias) do
    create(:content_id_alias, content_id: embedded_content_id)
  end

  let(:fake_content_id) { SecureRandom.uuid }

  before do
    allow_any_instance_of(EmbeddedContentFinderService).to receive(:find_content_references) do |_instance, content|
      references = []
      content.scan(/\{\{embed:([^:]+):([^}]+)\}\}/) do |document_type, identifier|
        embed_code = "{{embed:#{document_type}:#{identifier}}}"
        content_reference = double("ContentReference",
                                   embed_code: embed_code,
                                   identifier: identifier)
        references << content_reference
      end
      references
    end

    allow(::Queries::GetEmbeddedEditionsFromHostEdition).to receive(:call) do
      all_embedded_editions = {}
      all_embedded_editions[embedded_content_id] = embedded_edition if defined?(embedded_content_id)
      all_embedded_editions[embedded_edition_2.document.content_id] = embedded_edition_2 if defined?(embedded_edition_2)
      all_embedded_editions[other_embedded_edition.document.content_id] = other_embedded_edition if defined?(other_embedded_edition)
      all_embedded_editions[embedded_content_id_alias.name] = embedded_edition if defined?(embedded_content_id_alias)
      all_embedded_editions
    end
  end

  describe "#render_embedded_content" do
    context "when the content reference does not have a corresponding live Edition" do
      context "when there is one edition that hasn't been found" do
        let(:details) { { body: "some string with a reference: {{embed:content_block_contact:#{fake_content_id}}}" } }

        before do
          allow(::Queries::GetEmbeddedEditionsFromHostEdition).to receive(:call).and_return({})
        end

        it "alerts Sentry and returns the content as is" do
          expect(GovukError).to receive(:notify).with(CommandError.new(
                                                        code: 422,
                                                        message: "Could not find a live edition for embedded content ID: #{fake_content_id}",
                                                      ))
          expect(described_class.new(edition).render_embedded_content(details)).to eq({
            body: "some string with a reference: {{embed:content_block_contact:#{fake_content_id}}}",
          })
        end
      end
    end

    context "When the embed code has a UUID" do
      let(:embed_code) { "{{embed:content_block_contact:#{embedded_content_id}}}" }
      it_behaves_like "renders embedded content"
    end

    context "When the embed code has a content ID alias" do
      let(:embed_code) { "{{embed:content_block_contact:#{embedded_content_id_alias.name}}}" }

      before do
        allow(::Queries::GetEmbeddedEditionsFromHostEdition).to receive(:call) do
          all_embedded_editions = {}
          all_embedded_editions[embedded_content_id_alias.name] = embedded_edition
          all_embedded_editions[embedded_content_id] = embedded_edition if defined?(embedded_content_id)
          all_embedded_editions[embedded_edition_2.document.content_id] = embedded_edition_2 if defined?(embedded_edition_2)
          all_embedded_editions[other_embedded_edition.document.content_id] = other_embedded_edition if defined?(other_embedded_edition)
          all_embedded_editions
        end
      end

      it_behaves_like "renders embedded content"
    end
  end
end
