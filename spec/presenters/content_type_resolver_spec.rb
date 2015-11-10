require "rails_helper"

RSpec.describe Presenters::ContentTypeResolver do
  subject { described_class.new("html") }

  it "inlines content of the specified content type" do
    result = subject.resolve(
      body: [
        { content_type: "html", content: "<p>body</p>" },
        { content_type: "text", content: "body" },
      ]
    )

    expect(result).to eq(
      body: "<p>body</p>"
    )
  end

  it "works for string keys as well as symbols" do
    result = subject.resolve(
      "body" => [
        { "content_type" => "html", "content" => "<p>body</p>" },
        { "content_type" => "text", "content" => "body" },
      ]
    )

    expect(result).to eq(
      "body" => "<p>body</p>"
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

  it "recurses on nested hashes" do
    result = subject.resolve(
      details: {
        foo: {
          bar: {
            content: [
              { content_type: "html", content: "<p>body</p>" }
            ]
          }
        }
      }
    )

    expect(result).to eq(
      details: {
        foo: {
          bar: {
            content: "<p>body</p>"
          }
        }
      }
    )
  end

  it "recurses on nested arrays" do
    result = subject.resolve(
      paragraphs: [
        [
          [
            {
              body: [
                { content_type: "html", content: "<p>body</p>" }
              ]
            }
          ]
        ]
      ]
    )

    expect(result).to eq(
      paragraphs: [
        [
          [
            {
              body: "<p>body</p>"
            }
          ]
        ]
      ]
    )
  end
end
