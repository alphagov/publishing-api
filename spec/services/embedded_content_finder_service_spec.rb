RSpec.shared_examples "finds references" do |document_type|
  describe "when content is a #{document_type}" do
    let(:editions) do
      [
        create(:edition,
               state: "published",
               document_type:,
               content_store: "live",
               details: { title: "Some Title" }),
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

    let(:content_id_alias_1) do
      create(:content_id_alias, name: "some-friendly-name", content_id: editions[0].content_id)
    end
    let(:content_id_alias_2) do
      create(:content_id_alias, name: "some-other-friendly-name", content_id: editions[1].content_id)
    end
    let(:draft_content_id_alias) do
      create(:content_id_alias, name: "draft-friendly-name", content_id: draft_edition.content_id)
    end

    %w[body downtime_message more_information].each do |field_name|
      it "finds content references" do
        details = { field_name => "{{embed:#{document_type}:#{content_id_alias_1.name}}} {{embed:#{document_type}:#{content_id_alias_2.name}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "finds content references when #{field_name} is an array of hashes" do
        details = { field_name => [{ "content" => "{{embed:#{document_type}:#{content_id_alias_1.name}}} {{embed:#{document_type}:#{content_id_alias_2.name}}}" }] }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "finds content references when #{field_name} is a multipart document" do
        details = {
          field_name => [
            {
              body: [
                {
                  content: "some string with a reference: {{embed:#{document_type}:#{content_id_alias_1.name}}}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-slug",
              title: "Some title",
            },
            {
              body: [
                {
                  content: "some string with another reference: {{embed:#{document_type}:#{content_id_alias_2.name}}}",
                  content_type: "text/govspeak",
                },
              ],
              slug: "some-other-slug",
              title: "Some other title",
            },
          ],
        }
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "finds content references when the field is a hash" do
        details = { field_name => { title: "{{embed:#{document_type}:#{content_id_alias_1.name}}}", slug: "{{embed:#{document_type}:#{content_id_alias_2.name}}}", current: true } }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "errors when given an alias for an Edition that is still draft" do
        details = { field_name => "{{embed:#{document_type}:#{draft_content_id_alias.name}}}" }

        expect {
          EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)
        }.to raise_error(
          CommandError,
          "Could not find any live editions in locale #{Edition::DEFAULT_LOCALE} for: #{draft_content_id_alias.name}",
        )
      end

      it "errors when given an alias for a live Edition that is not available in the current locale" do
        details = { field_name => "{{embed:#{document_type}:#{content_id_alias_1.name}}}" }

        expect {
          EmbeddedContentFinderService.new.fetch_linked_content_ids(details, "foo")
        }.to raise_error(
          CommandError,
          "Could not find any live editions in locale foo for: #{content_id_alias_1.name}",
        )
      end
    end
  end
end

RSpec.describe EmbeddedContentFinderService do
  describe ".fetch_linked_content_ids" do
    EmbeddedContentFinderService::SUPPORTED_DOCUMENT_TYPES.each do |document_type|
      include_examples "finds references", document_type
    end

    it "returns an empty hash where there are no embeds" do
      details = { body: "Hello world!" }

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

      expect(links).to eq([])
    end

    it "errors when given a content ID that has no live editions" do
      details = { body: "{{embed:contact:00000000-0000-0000-0000-000000000000}}" }

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE) }.to raise_error(CommandError)
    end

    context "when the field value is an array" do
      it "returns an empty array" do
        details = { body: [] }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)
        expect(result).to eq([])
      end
    end

    context "when the field value is a hash" do
      it "returns an empty array" do
        details = { body: {} }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)
        expect(result).to eq([])
      end
    end

    context "when the field value is a nested hash" do
      it "returns an empty array" do
        details = { body: { foo: {} } }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)
        expect(result).to eq([])
      end
    end

    context "when the field value is nil" do
      it "returns an empty array" do
        details = { body: nil }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)
        expect(result).to eq([])
      end
    end

    context "when the field value is a boolean" do
      it "returns an empty array" do
        details = { foo: true }
        result = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)
        expect(result).to eq([])
      end
    end
  end

  describe ".find_content_references" do
    it "returns nil if the argument isn't a scannable string" do
      expect { EmbeddedContentFinderService.new.find_content_references(false).to eq([]) }
    end
  end
end
