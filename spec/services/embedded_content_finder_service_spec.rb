RSpec.describe EmbeddedContentFinderService do
  let(:contacts) do
    [
      create(:edition,
             state: "published",
             document_type: "contact",
             content_store: "live",
             details: { title: "Some Title" }),
      create(:edition,
             state: "published",
             document_type: "contact",
             content_store: "live",
             details: { title: "Some other Title" }),
    ]
  end
  let(:draft_contact) do
    create(:edition,
           state: "draft",
           document_type: "contact",
           content_store: "live",
           details: { title: "Some Title" })
  end

  describe ".fetch_linked_content_ids" do
    it "returns an empty hash where there are no embeds" do
      body = "Hello world!"

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE)

      expect(links).to eq([])
    end

    it "finds contact references" do
      body = "{{embed:contact:#{contacts[0].content_id}}} {{embed:contact:#{contacts[1].content_id}}}"

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE)

      expect(links).to eq([contacts[0].content_id, contacts[1].content_id])
    end

    it "finds contact references when body is an array of hashes" do
      body = [{ content: "{{embed:contact:#{contacts[0].content_id}}} {{embed:contact:#{contacts[1].content_id}}}" }]

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE)

      expect(links).to eq([contacts[0].content_id, contacts[1].content_id])
    end

    it "errors when given a content ID that has no live editions" do
      body = "{{embed:contact:00000000-0000-0000-0000-000000000000}}"

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE) }.to raise_error(CommandError)
    end

    it "errors when given a content ID that is still draft" do
      body = "{{embed:contact:#{draft_contact.content_id}}}"

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE) }.to raise_error(CommandError)
    end

    it "errors when given a live content ID that is not available in the current locale" do
      body = "{{embed:contact:#{contacts[0].content_id}}}"

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(body, "foo") }.to raise_error(CommandError)
    end
  end
end
