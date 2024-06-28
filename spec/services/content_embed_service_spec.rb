RSpec.describe ContentEmbedService do
  describe ".render" do
    it "renders a contact" do
      contact = create(:edition,
                       state: "published",
                       document_type: "contact",
                       content_store: "live",
                       details: { title: "Some Title" })

      body = <<-DOC
      <h1>Heading</h1>

      <p>Contact 1</p>
      <p>{{embed:contact:#{contact.document.content_id}}}</p>
      DOC

      result = ContentEmbedService.new(body).render
      expected = <<-DOC
        <h1>Heading</h1>

        <p>Contact 1</p>
        <p>#{contact.details[:title]}</p>
      DOC

      expect(result.gsub(/\s+/, " ")).to eq(expected.gsub(/\s+/, " "))
    end

    it "renders multiple contacts" do
      contact1 = create(:edition,
                        state: "published",
                        document_type: "contact",
                        content_store: "live",
                        details: { title: "Some Title" })

      contact2 = create(:edition,
                        state: "published",
                        document_type: "contact",
                        content_store: "live",
                        details: { title: "Some other Title" })

      body = "{{embed:contact:#{contact1.document.content_id}}} {{embed:contact:#{contact2.document.content_id}}}"

      result = ContentEmbedService.new(body).render
      expected = "#{contact1.details[:title]} #{contact2.details[:title]}"

      expect(result).to eq(expected)
    end
  end
end
