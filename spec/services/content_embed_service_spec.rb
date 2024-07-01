RSpec.describe ContentEmbedService do
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

  describe ".embedded_editions" do
    it "returns all editions" do
      body = "{{embed:contact:#{contacts[0].document.content_id}}} {{embed:contact:#{contacts[1].document.content_id}}}"

      embedded_editions = ContentEmbedService.new(body).embedded_editions

      expect(embedded_editions[0].embed_code).to eq("{{embed:contact:#{contacts[0].document.content_id}}}")
      expect(embedded_editions[0].edition).to eq(contacts[0])

      expect(embedded_editions[1].embed_code).to eq("{{embed:contact:#{contacts[1].document.content_id}}}")
      expect(embedded_editions[1].edition).to eq(contacts[1])
    end
  end

  describe ".fetch_links" do
    it "returns an empty hash where there are no embeds" do
      body = "Hello world!"

      links = ContentEmbedService.new(body).fetch_links

      expect(links).to eq({})
    end

    it "marshals embedded editions into links" do
      body = "{{embed:contact:#{contacts[0].document.content_id}}} {{embed:contact:#{contacts[1].document.content_id}}}"

      links = ContentEmbedService.new(body).fetch_links

      expect(links).to eq({ "contact" => [contacts[0].document.content_id, contacts[1].document.content_id] })
    end
  end

  describe ".render" do
    it "renders a contact" do
      body = <<-DOC
      <h1>Heading</h1>

      <p>Contact 1</p>
      <p>{{embed:contact:#{contacts[0].document.content_id}}}</p>
      DOC

      result = ContentEmbedService.new(body).render
      expected = <<-DOC
        <h1>Heading</h1>

        <p>Contact 1</p>
        <p>#{contacts[0].details[:title]}</p>
      DOC

      expect(result.gsub(/\s+/, " ")).to eq(expected.gsub(/\s+/, " "))
    end

    it "renders multiple contacts" do
      body = "{{embed:contact:#{contacts[0].document.content_id}}} {{embed:contact:#{contacts[1].document.content_id}}}"

      result = ContentEmbedService.new(body).render
      expected = "#{contacts[0].details[:title]} #{contacts[1].details[:title]}"

      expect(result).to eq(expected)
    end
  end
end
