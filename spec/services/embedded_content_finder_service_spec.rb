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

    it "finds content references" do
      body = "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}"

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE)

      expect(links).to eq([editions[0].content_id, editions[1].content_id])
    end

    it "finds content references when body is an array of hashes" do
      body = [{ "content" => "{{embed:#{document_type}:#{editions[0].content_id}}} {{embed:#{document_type}:#{editions[1].content_id}}}" }]

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE)

      expect(links).to eq([editions[0].content_id, editions[1].content_id])
    end

    it "errors when given a content ID that is still draft" do
      body = "{{embed:#{document_type}:#{draft_edition.content_id}}}"

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE) }.to raise_error(CommandError)
    end

    it "errors when given a live content ID that is not available in the current locale" do
      body = "{{embed:#{document_type}:#{editions[0].content_id}}}"

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(body, "foo") }.to raise_error(CommandError)
    end
  end
end

RSpec.describe EmbeddedContentFinderService do
  describe ".fetch_linked_content_ids" do
    EmbeddedContentFinderService::SUPPORTED_DOCUMENT_TYPES.each do |document_type|
      include_examples "finds references", document_type
    end

    it "returns an empty hash where there are no embeds" do
      body = "Hello world!"

      links = EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE)

      expect(links).to eq([])
    end

    it "errors when given a content ID that has no live editions" do
      body = "{{embed:contact:00000000-0000-0000-0000-000000000000}}"

      expect { EmbeddedContentFinderService.new.fetch_linked_content_ids(body, Edition::DEFAULT_LOCALE) }.to raise_error(CommandError)
    end
  end
end
