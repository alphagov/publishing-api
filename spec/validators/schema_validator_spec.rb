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

  subject(:validator) { SchemaValidator.new(type: :schema, schema: schema) }

  describe "#validate" do
    context "unknown schema name" do
      let(:schema) { nil }
      let(:payload) { { schema_name: "test" } }

      it "logs to airbrake with an unknown schema_name" do
        expect(Airbrake)
          .to receive(:notify)
          .with(an_instance_of(Errno::ENOENT), a_hash_including(:parameters))
        validator.validate(payload)
      end
    end

    context "valid payload" do
      let(:payload) { { a: 1 } }

      it "returns true" do
        expect(validator.validate(payload)).to be true
      end
    end

    context "invalid payload" do
      let(:payload) { { b: 1 } }

      it "returns false" do
        expect(validator.validate(payload)).to be false
      end
    end
  end

  describe "#errors" do
    subject do
      validator.validate(payload)
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
  end
end
