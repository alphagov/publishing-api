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

    %w[body downtime_message more_information].each do |field_name|
      it "finds content references" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there is more than one content reference in the field" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there are field references in the field" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}/title}} {{embed:#{document_type}:#{editions[0].content_id}/another}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[0].content_id])
      end

      it "finds content references when #{field_name} is an array of hashes" do
        details = { field_name => [{ "content" => "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }] }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

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
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

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
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

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
        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links.length).to eq(6)
        expect(links.count(editions[0].content_id)).to eq(2)
        expect(links.count(editions[1].content_id)).to eq(4)
      end

      it "finds content references when the field is a hash" do
        details = { field_name => { title: "{{embed:#{document_type}:#{editions[0].content_id}}}", slug: "{{embed:#{document_type}:#{editions[1].content_id}}}", current: true } }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[1].content_id])
      end

      it "returns duplicates when there is more than one content reference in the field and the field is a hash" do
        details = { field_name => { title: "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[0].content_id}}}", slug: "{{embed:#{document_type}:#{editions[1].content_id}}}", current: true } }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

        expect(links).to eq([editions[0].content_id, editions[0].content_id, editions[1].content_id])
      end

      it "does not return a content ID that is still draft" do
        details = { field_name => "{{embed:#{document_type}:#{draft_edition.content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, "foo")

        expect(links).to eq([])
      end

      it "does not return a live content ID that is not available in the current locale" do
        details = { field_name => "{{embed:#{document_type}:#{editions[0].content_id}}}" }

        links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, "foo")

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

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, Edition::DEFAULT_LOCALE)

      expect(links).to eq([])
    end

    it "alerts Sentry when there is are embeds without live editions" do
      details = { body: "{{embed:contact:00000000-0000-0000-0000-000000000000}}" }
      expect(GovukError).to receive(:notify).with(CommandError.new(
                                                    code: 422,
                                                    message: "Could not find any live editions for embedded content IDs: 00000000-0000-0000-0000-000000000000",
                                                  ))

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(details, "foo")

      expect(links).to eq([])
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
