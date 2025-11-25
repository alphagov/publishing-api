RSpec.shared_examples "finds references" do |document_type|
  describe "when content is a #{document_type}" do
    let(:editions) do
      [
        create(:edition,
               state: "published",
               document_type:,
               content_store: "live",
               details: { title: "Some Title", another: "thing" }),
        create(:edition,
               state: "published",
               document_type:,
               content_store: "live",
               details: { title: "Some other Title" }),
      ]
    end

    let(:draft_edition) do
      create(:edition,
             state: "draft",
             document_type:,
             content_store: "live",
             details: { title: "Some Title" })
    end

    let(:content_id_aliases) do
      editions.map do |edition|
        create(:content_id_alias, content_id: edition.content_id)
      end
    end

    %w[body downtime_message more_information].each do |field_name|
      it "finds content references" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "supports content ID aliases" do
        details = { field_name => "{{embed:#{document_type}:#{content_id_aliases[0].name}}} {{embed:#{document_type}:#{content_id_aliases[1].name}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "supports mixed content ID aliases and UUIDS" do
        details = { field_name => "{{embed:#{document_type}:#{content_id_aliases[0].name}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there is more than one content reference in the field" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there is more than one alias in the field" do
        details = { field_name => "{{embed:#{document_type}:#{content_id_aliases[0].name}}} {{embed:#{document_type}:#{content_id_aliases[0].name}}} {{embed:#{document_type}:#{content_id_aliases[1].name}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there are field references in the field" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}/title}} {{embed:#{document_type}:#{editions[0].content_id}/another}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[0].content_id])
      end

      it "returns duplicates when there are field references and an alias in the field" do
        details = { field_name => "{{embed:#{document_type}:#{content_id_aliases[0].name}/title}} {{embed:#{document_type}:#{content_id_aliases[0].name}/another}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[0].content_id])
      end

      it "finds content references when #{field_name} is an array of hashes" do
        details = { field_name => [{ content: "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }] }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "finds content references when #{field_name} is a multipart document" do
        details = {
          field_name => [
            {
              body: [
                {
                  content: "some string with a reference: {{embed:#{document_type}:#{editions[0].content_id}}}",
                  content_type: "text/html",
                },
                {
                  content: "some string with a reference: {{embed:#{document_type}:#{editions[0].content_id}}}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-slug",
              title: "Some title",
            },
            {
              body: [
                {
                  content: "some string with another reference: {{embed:#{document_type}:#{editions[1].content_id}}}",
                  content_type: "text/html",
                },
                {
                  content: "some string with another reference: {{embed:#{document_type}:#{editions[1].content_id}}}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-other-slug",
              title: "Some other title",
            },
          ],
        }
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links.length).to eq(4)
        expect(links.count(editions[0].content_id)).to eq(2)
        expect(links.count(editions[1].content_id)).to eq(2)
      end

      it "returns duplicates when there is more than one content reference in the field and #{field_name} is a multipart document" do
        details = {
          field_name => [
            {
              body: [
                {
                  content: "some string with a reference: {{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[0].content_id}}}",
                  content_type: "text/html",
                },
                {
                  content: "some string with a reference: {{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[0].content_id}}}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-slug",
              title: "Some title",
            },
            {
              body: [
                {
                  content: "some string with another reference: {{embed:#{document_type}:#{editions[1].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}",
                  content_type: "text/html",
                },
                {
                  content: "some string with another reference: {{embed:#{document_type}:#{editions[1].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-other-slug",
              title: "Some other title",
            },
          ],
        }
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links.length).to eq(8)
        expect(links.count(editions[0].content_id)).to eq(4)
        expect(links.count(editions[1].content_id)).to eq(4)
      end

      it "returns duplicates when there is more than one content reference in the field and #{field_name} is a guide document" do
        details = {
          field_name => [
            {
              "title": "Key stage 3 and 4",
              "slug": "key-stage-3-and-4",
              "body": "some string with another reference: {{embed:#{document_type}:#{editions[0].content_id}}} and another {{embed:#{document_type}:#{editions[0].content_id}}}",
            },
            {
              "title": "Other compulsory subjects",
              "slug": "other-compulsory-subjects",
              "body": "some string with another reference: {{embed:#{document_type}:#{editions[1].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}",
            },
            {
              "title": "Overview",
              "slug": "overview",
              "body": "some string with another reference: {{embed:#{document_type}:#{editions[1].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}",
            },
          ],
        }
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links.length).to eq(6)
        expect(links.count(editions[0].content_id)).to eq(2)
        expect(links.count(editions[1].content_id)).to eq(4)
      end

      it "finds content references when the field is a hash" do
        details = { field_name => { title: "{{embed:#{document_type}:#{editions[0].content_id}}}", slug: "{{embed:#{document_type}:#{editions[1].content_id}}}", current: true } }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there is more than one content reference in the field and the field is a hash" do
        details = { field_name => { title: "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[0].content_id}}}", slug: "{{embed:#{document_type}:#{editions[1].content_id}}}", current: true } }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([editions[0].content_id, editions[0].content_id, editions[1].content_id])
      end

      it "does not return a content ID that is still draft" do
        details = { field_name => "{{embed:#{document_type}:#{draft_edition.content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

        expect(links).to eq([])
      end
    end
  end
end

RSpec.describe EmbeddedContentFinderService do
  describe ".fetch_linked_content_ids" do
    ContentBlockTools::ContentBlockReference::SUPPORTED_DOCUMENT_TYPES.each do |document_type|
      include_examples "finds references", document_type
    end

    it "returns an empty hash where there are no embeds" do
      details = { body: "Hello world!" }

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

      expect(links).to eq([])
    end

    it "alerts Sentry when there is are embeds without live editions" do
      details = { body: "{{embed:contact:00000000-0000-0000-0000-000000000000}}" }
      expect(GovukError).to receive(:notify).with(CommandError.new(
                                                    code: 422,
                                                    message: "Could not find any live editions for embedded content IDs: 00000000-0000-0000-0000-000000000000",
                                                  ))

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

      expect(links).to eq([])
    end

    it "alerts Sentry when there is an invalid alias in the embed code" do
      details = { body: "{{embed:contact:some-content-id-alias}}" }
      expect(GovukError).to receive(:notify).with(CommandError.new(
                                                    code: 422,
                                                    message: "Could not find a Content ID for alias some-content-id-alias",
                                                  ))

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)

      expect(links).to eq([])
    end

    context "when the field value is an array" do
      it "returns an empty array" do
        details = { body: [] }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)
        expect(result).to eq([])
      end
    end

    context "when the field value is a hash" do
      it "returns an empty array" do
        details = { body: {} }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)
        expect(result).to eq([])
      end
    end

    context "when the field value is a nested hash" do
      it "returns an empty array" do
        details = { body: { foo: {} } }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)
        expect(result).to eq([])
      end
    end

    context "when the field value is nil" do
      it "returns an empty array" do
        details = { body: nil }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)
        expect(result).to eq([])
      end
    end

    context "when the field value is a boolean" do
      it "returns an empty array" do
        details = { foo: true }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details)
        expect(result).to eq([])
      end
    end
  end

  describe ".find_content_references(content_references)" do
    it "returns nil if the argument isn't a scannable string" do
      expect(EmbeddedContentFinderService.new.find_content_references(false)).to eq([])
    end

    let(:input_to_scan) do
      "<p>{{embed:content_block_contact:alias-1}}</p>" \
        "<p>{{embed:content_block_contact:id-2}}</p>"
    end

    let(:found_references) { [double("ref_alias_1"), double("ref_id_2")] }
    let(:transformed_references) { [double("ref_id_1"), double("ref_id_2")] }
    let(:normaliser) { instance_double(EmbeddedContentFinderService::ContentReferenceIdentifierNormaliser) }

    before do
      allow(ContentBlockTools::ContentBlockReference).to receive(:find_all_in_document)
        .and_return(found_references)

      allow(EmbeddedContentFinderService::ContentReferenceIdentifierNormaliser).to receive(:new)
         .and_return(normaliser)
      allow(normaliser).to receive(:call).and_return(transformed_references)
    end

    it "uses ContentBlockTools::ContentBlockReference.find_all_in_document to pick out references" do
      EmbeddedContentFinderService.new.find_content_references(input_to_scan)

      expect(ContentBlockTools::ContentBlockReference)
        .to have_received(:find_all_in_document).with(input_to_scan)
    end

    it "uses ContentReferenceIdentifierNormaliser to convert content_id_aliases to content_ids" do
      EmbeddedContentFinderService.new.find_content_references(input_to_scan)

      expect(EmbeddedContentFinderService::ContentReferenceIdentifierNormaliser)
        .to have_received(:new).with(content_references: found_references)

      expect(normaliser).to have_received(:call)
    end

    it "returns transformed references, with content_id_aliases replaced by content_ids" do
      expect(EmbeddedContentFinderService.new.find_content_references(input_to_scan))
        .to eq(transformed_references)
    end
  end

  describe EmbeddedContentFinderService::ContentReferenceIdentifierNormaliser do
    describe "#call" do
      let(:ref_alias_1) do
        FakeContentBlockReference.new(
          document_type: "content_block_contact",
          identifier: "alias-1",
          embed_code: "{{embed:content_block_contact:alias-1}}",
        )
      end

      let(:ref_alias_2) do
        FakeContentBlockReference.new(
          document_type: "content_block_contact",
          identifier: "alias-2",
          embed_code: "{{embed:content_block_contact:alias-2}}",
        )
      end

      let(:ref_id_3) do
        FakeContentBlockReference.new(
          document_type: "content_block_contact",
          identifier: "id-3",
          embed_code: "{{embed:content_block_contact:id-3}}",
        )
      end

      let(:ref_id_4) do
        FakeContentBlockReference.new(
          document_type: "content_block_contact",
          identifier: "id-4",
          embed_code: "{{embed:content_block_contact:id-4}}",
        )
      end

      let(:content_id_alias_1) { instance_double(ContentIdAlias, name: "alias-1", content_id: "id-1") }
      let(:content_id_alias_2) { instance_double(ContentIdAlias, name: "alias-2", content_id: "id-2") }

      let(:content_references) { [ref_alias_1, ref_alias_2, ref_id_3, ref_id_4] }
      let(:found_content_id_aliases) { [content_id_alias_1, content_id_alias_2] }

      before do
        allow(ref_alias_1).to receive(:identifier_is_alias?).and_return(true)
        allow(ref_alias_2).to receive(:identifier_is_alias?).and_return(true)
        allow(ref_id_3).to receive(:identifier_is_alias?).and_return(false)
        allow(ref_id_4).to receive(:identifier_is_alias?).and_return(false)

        allow(ContentIdAlias).to receive(:where).and_return(found_content_id_aliases)
      end

      it "retrieves ContentIdAlias records for ContentReferences with identifiers considered aliases" do
        described_class.new(content_references: content_references).call

        expect(ContentIdAlias).to have_received(:where).with(name: %w[alias-1 alias-2])
      end

      context "when the aliases identified match ContentIdAlias records in the db" do
        it "returns the content references with the aliases substituted for content_ids" do
          transformed_references = described_class.new(content_references: content_references).call

          expect(transformed_references.map(&:to_h)).to eq(
            [
              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:alias-1}}",
                identifier: "id-1" },

              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:alias-2}}",
                identifier: "id-2" },

              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:id-3}}",
                identifier: "id-3" },

              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:id-4}}",
                identifier: "id-4" },
            ],
          )
        end
      end

      context "when an alias identified DOES NOT match a ContentIdAlias record in the db" do
        let(:found_content_id_aliases) { [content_id_alias_2] }
        let(:command_error) { double("CommandError") }

        before do
          allow(ContentIdAlias).to receive(:where).and_return(found_content_id_aliases)
          allow(CommandError).to receive(:new).and_return(command_error)
          allow(GovukError).to receive(:notify).with(command_error)
        end

        it "returns only the content references with matching ContentIdAlias records (ids replacing aliases)" do
          transformed_references = described_class.new(content_references: content_references).call

          expect(transformed_references.map(&:to_h)).to eq(
            [
              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:alias-2}}",
                identifier: "id-2" },

              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:id-3}}",
                identifier: "id-3" },

              { document_type: "content_block_contact",
                embed_code: "{{embed:content_block_contact:id-4}}",
                identifier: "id-4" },
            ],
          )
        end

        it "logs the fact that the referenced ContentIdAlias was not found" do
          described_class.new(content_references: content_references).call

          expect(CommandError).to have_received(:new).with(
            code: 422,
            message: "Could not find a Content ID for alias alias-1",
          )
          expect(GovukError).to have_received(:notify).with(command_error)
        end
      end
    end
  end
end

class FakeContentBlockReference
  def initialize(document_type:, identifier:, embed_code:)
    @document_type = document_type
    @identifier = identifier
    @embed_code = embed_code
  end
  attr_reader :document_type, :identifier, :embed_code

  def identifier_is_alias?
    raise "this should be stubbed"
  end

  def to_h
    {
      document_type: document_type,
      identifier: identifier,
      embed_code: embed_code,
    }
  end
end
