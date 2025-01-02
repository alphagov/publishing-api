RSpec.describe Presenters::ContentTypeResolver do
  subject { described_class.new("html") }

  it "inlines content of the specified content type" do
    result = subject.resolve(
      body: [
        { content_type: "html", content: "<p>body</p>" },
        { content_type: "text", content: "body" },
      ],
    )

    expect(result).to eq(
      body: "<p>body</p>",
    )
  end

  it "works for string keys as well as symbols" do
    result = subject.resolve(
      "body" => [
        { "content_type" => "html", "content" => "<p>body</p>" },
        { "content_type" => "text", "content" => "body" },
      ],
    )

    expect(result).to eq(
      "body" => "<p>body</p>",
    )
  end

  it "does not affect other fields" do
    result = subject.resolve(
      string: "string",
      array: [],
      number: 123,
    )

    expect(result).to eq(
      string: "string",
      array: [],
      number: 123,
    )
  end

  it "handles hashes with content types but no content field" do
    result = subject.resolve([
      content_type: "application/pdf",
      path: "some/document.pdf",
    ])

    expect(result).to eq([
      content_type: "application/pdf",
      path: "some/document.pdf",
    ])
  end

  it "recurses on nested hashes" do
    result = subject.resolve(
      details: {
        foo: {
          bar: {
            content: [
              { content_type: "html", content: "<p>body</p>" },
            ],
          },
        },
      },
    )

    expect(result).to eq(
      details: {
        foo: {
          bar: {
            content: "<p>body</p>",
          },
        },
      },
    )
  end

  it "recurses on nested arrays" do
    result = subject.resolve(
      paragraphs: [
        [
          [
            {
              body: [
                { content_type: "html", content: "<p>body</p>" },
              ],
            },
          ],
        ],
      ],
    )

    expect(result).to eq(
      paragraphs: [
        [
          [
            {
              body: "<p>body</p>",
            },
          ],
        ],
      ],
    )
  end

  it "doesn't resolve incomplete multi-type content" do
    result = subject.resolve(
      details: {
        body: {
          content: [
            { content: "<p>body</p>" },
            { content_type: "html" },
          ],
        },
      },
    )
    expect(result).to eq(
      details: {
        body: {
          content: [
            { content: "<p>body</p>" },
            { content_type: "html" },
          ],
        },
      },
    )
  end
end
