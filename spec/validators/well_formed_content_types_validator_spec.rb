require "rails_helper"

class Record
  attr_reader :errors

  def initialize
    @errors = ActiveModel::Errors.new(self)
  end
end

RSpec.describe WellFormedContentTypesValidator do
  let(:record) { Record.new }
  let(:attribute) { :some_attribute }

  let(:options) { {} }
  subject { described_class.new({ attributes: [attribute] }.merge(options)) }

  it "accepts arbitrary values" do
    value = "some_value"
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty

    value = :some_symbol
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty

    value = 123
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty

    value = { some: "hash" }
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty

    value = [{ an: "array" }, { of: "hashes" }]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty
  end

  it "accepts well-formed content types" do
    value = [{ content_type: "text/html", content: "<p>content</p>" }]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty

    value = { foo: [{ content_type: "text/html", content: "<p>content</p>" }] }
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty

    value = [{ "content_type" => "text/html", "content" => "<p>content</p>" }]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_empty
  end

  it "rejects values where the content key is missing" do
    value = [{ content_type: "text/html" }]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_present
    expect(record.errors.messages_for(:some_attribute)).to eq(["the 'text/html' content type does not contain content"])

    record.errors.clear

    value = { foo: [{ content_type: "text/html" }] }
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_present
    expect(record.errors.messages_for(:some_attribute)).to eq(["the 'text/html' content type does not contain content"])

    record.errors.clear

    value = [{ content_type: "text/plain" }, { content_type: "text/html", content: "<p>content</p>" }]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_present
    expect(record.errors.messages_for(:some_attribute)).to eq(["the 'text/plain' content type does not contain content"])
  end

  context "when the 'must_include' option is set to 'text/html'" do
    let(:options) { { must_include: "text/html" } }

    it "rejects values that do not have a content type of 'text/html'" do
      value = [{ content_type: "text/plain", content: "content" }]
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_present
      expect(record.errors.messages_for(:some_attribute)).to eq(["the 'text/html' content type is mandatory and it is missing"])
    end
  end

  context "when the 'must_include' option is not set" do
    let(:options) { {} }

    it "accepts values that do not have a content type of 'text/html'" do
      value = [{ content_type: "text/plain", content: "content" }]
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_empty
    end
  end

  context "when the 'must_include_one_of' option is set to ['text/html', 'text/govspeak']" do
    let(:options) { { must_include_one_of: %w[text/html text/govspeak] } }

    it "rejects values that do not have a content type of 'text/html' or 'text/govspeak'" do
      value = [{ content_type: "text/plain", content: "content" }]
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_present
      expect(record.errors.messages_for(:some_attribute)).to eq(["there must be at least one content type of (text/html, text/govspeak)"])
    end

    it "accepts values that do have a content type of 'text/govspeak'" do
      value = [{ content_type: "text/govspeak", content: "content" }]
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_empty
    end

    it "accepts values that have a content type of 'text/govspeak' and 'text/html'" do
      value = [
        { content_type: "text/govspeak", content: "content" },
        { content_type: "text/html", content: "content" },
      ]
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_empty
    end
  end

  it "rejects values that have duplicate content types" do
    value = [
      { content_type: "text/html", content: "<p>content</p>" },
      { content_type: "text/html", content: "<p>content</p>" },
    ]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_present
    expect(record.errors.messages_for(:some_attribute)).to eq(["there are 2 instances of the 'text/html' content type - there should be 1"])

    record.errors.clear

    value = [
      { content_type: "text/html", content: "<p>content</p>" },
      { content_type: "text/plain", content: "content" },
      { content_type: "text/plain", content: "content" },
    ]
    subject.validate_each(record, attribute, value)
    expect(record.errors).to be_present
    expect(record.errors.messages_for(:some_attribute)).to eq(["there are 2 instances of the 'text/plain' content type - there should be 1"])
  end

  context "when the value is invalid for more than one reason" do
    let(:options) { { must_include: "text/html" } }
    let(:value) { [{ content_type: "text/plain" }] }

    it "communicates all of those reasons back to the programmer in one go" do
      subject.validate_each(record, attribute, value)
      expect(record.errors).to be_present

      error_messages = record.errors.messages_for(attribute)
      expect(error_messages).to include("the 'text/plain' content type does not contain content")
      expect(error_messages).to include("the 'text/html' content type is mandatory and it is missing")
    end
  end

  it "does not clobber existing errors for the attribute" do
    record.errors.add(attribute, "some existing error")

    value = "some_value"
    subject.validate_each(record, attribute, value)
    expect(record.errors[attribute].size).to eq(1)

    value = [{ content_type: "text/html" }]
    subject.validate_each(record, attribute, value)
    expect(record.errors[attribute].size).to eq(2)
  end
end
