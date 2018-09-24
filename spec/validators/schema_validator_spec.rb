require "rails_helper"

RSpec.describe SchemaValidator do
  let(:schema) do
    {
      type: "object",
      required: ["a"],
      properties: {
        a: { "type" => "integer" }
      }
    }.deep_stringify_keys
  end

  subject(:validator) { SchemaValidator.new(schema: schema, payload: payload) }

  describe "#validate" do
    context "unknown schema name" do
      let(:schema) { nil }
      let(:payload) { { schema_name: "nonexistent-schema" } }

      it "is invalid and has an error" do
        expect(validator.valid?).to be false
        expect(validator.errors).to match_array(
          ["Unable to find schema for schema_name nonexistent-schema"]
        )
      end
    end

    context "empty schema name" do
      let(:schema) { nil }
      let(:payload) { { schema_name: "" } }

      it "returns false" do
        expect(validator.valid?).to be false
      end
    end

    context "valid payload" do
      let(:payload) { { a: 1 } }

      it "returns true" do
        expect(validator.valid?).to be true
      end
    end

    context "invalid payload" do
      let(:payload) { { b: 1 } }

      it "returns false" do
        expect(validator.valid?).to be false
      end
    end
  end

  describe "#errors" do
    subject do
      validator.valid?
      validator.errors
    end

    context "valid payload" do
      let(:payload) { { a: 1 } }

      it "is empty" do
        expect(subject).to be_empty
      end
    end

    context "invalid payload" do
      let(:payload) { { b: 1 } }

      it "is populated" do
        expect(subject.count).to eq 1
        expected = /property '#\/' did not contain a required property of 'a'/
        expect(subject.first[:message]).to match expected
      end
    end

    context "empty schema name" do
      let(:schema) { nil }
      let(:payload) { { schema_name: "" } }
      let(:message) { "Schema could not be validated as the schema_name was not provided" }

      it "has an error" do
        expect(subject).to match_array([message])
      end
    end
  end
end
