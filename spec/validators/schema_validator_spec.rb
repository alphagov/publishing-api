require "rails_helper"

RSpec.describe SchemaValidator do
  let(:schema) do
    {
      "type" => "object",
      "required" => ["a"],
      "properties" => {
        "a" => { "type" => "integer" }
      }
    }
  end

  subject(:validator) do
    SchemaValidator.new(payload, type: :schema, schema: schema)
  end

  context "schema" do
    let(:schema) { nil }
    let(:payload) { { schema_name: 'test' } }

    it "logs to airbrake with an unknown schema_name" do
      expect(Airbrake).to receive(:notify_or_ignore)
        .with(an_instance_of(Errno::ENOENT), a_hash_including(:parameters))
      validator.validate
    end
  end

  context "valid payload" do
    let(:payload) { { a: 1 } }

    it "does not report to airbrake" do
      expect(Airbrake).to_not receive(:notify_or_ignore)
      validator.validate
    end

    it "logs to airbrake when the payload is invalid" do
      expect(validator.validate).to be true
    end
  end

  context "invalid payload" do
    let(:payload) { { b: 1 } }

    it "reports to airbrake" do
      expect(Airbrake).to receive(:notify_or_ignore)
      validator.validate
    end

    it "logs to airbrake when the payload is invalid" do
      expect(validator.validate).to be false
    end
  end

  context "exceptions" do
    let(:payload) { { schema_name: 'placeholder_test' } }

    it "does not report to airbrake" do
      expect(Airbrake).to_not receive(:notify_or_ignore)
      validator.validate
    end
  end
end
