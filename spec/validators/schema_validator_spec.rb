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
    SchemaValidator.new(type: :schema, schema: schema)
  end

  context "schema" do
    let(:schema) { nil }
    let(:payload) { { schema_name: 'test' } }

    it "logs to airbrake with an unknown schema_name" do
      expect(Airbrake).to receive(:notify_or_ignore)
        .with(an_instance_of(Errno::ENOENT), a_hash_including(:parameters))
      validator.validate(payload)
    end
  end

  context "valid payload" do
    let(:payload) { { a: 1 } }

    it "does not report to airbrake" do
      expect(Airbrake).to_not receive(:notify_or_ignore)
      validator.validate(payload)
    end

    it "logs to airbrake when the payload is invalid" do
      expect(validator.validate(payload)).to be true
    end
  end

  context "invalid payload" do
    let(:payload) { { b: 1 } }

    it "reports to airbrake" do
      expect(Airbrake).to receive(:notify_or_ignore)
      validator.validate(payload)
    end

    it "logs to airbrake when the payload is invalid" do
      expect(validator.validate(payload)).to be false
    end
  end

  context "exceptions" do
    let(:payload) { { schema_name: 'placeholder_test' } }

    it "does not report to airbrake" do
      expect(Airbrake).to_not receive(:notify_or_ignore)
      validator.validate(payload)
    end
  end

  context "schema with format/schema_name alternatives" do
    let(:schema) {
      {
        "oneOf" => [
          {
            "properties" => {
              "format" => { "type" => "string" },
              "title" => { "type" => "string" },
            },
            "additionalProperties" => false,
            "required" => %w{format title},
          },
          {
            "properties" => {
              "schema_name" => { "type" => "string" },
              "document_type" => { "type" => "string" },
            },
            "additionalProperties" => false,
            "required" => %w{schema_name document_type format}
          }
        ]
      }
    }

    context "when schema_name is provided" do
      let(:payload) {
        { schema_name: "foo" }
      }
      it "reports useful validation errors" do
        expect(Airbrake).to receive(:notify_or_ignore) do |error, opts|
          expect(error[:error_message]).to eq("Error validating payload against schema 'foo'")
          expect(opts[:parameters][:errors][0]).to match(
            a_hash_including(
              message: a_string_starting_with("The property '#/' of type Hash did not match"),
              failed_attribute: "OneOf",
              errors: {
                oneof_0: {
                  0 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'title'"),
                    failed_attribute: "Required",
                  ),
                  1 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'format'"),
                    failed_attribute: "Required",
                  ),
                  2 => a_hash_including(
                    message: a_string_starting_with("The property '#/' contains additional properties [\"schema_name\"] outside of the schema when none are allowed"),
                    failed_attribute: "AdditionalProperties"
                  )
                },
                oneof_1: {
                  0 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'format'"),
                    failed_attribute: "Required",
                  ),
                  1 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'document_type'"),
                    failed_attribute: "Required",
                  ),
                }
              }
            )
          )
        end
        validator.validate(payload)
      end
    end

    context "when format is provided" do
      let(:payload) {
        { format: "foo" }
      }
      it "reports useful validation errors" do
        expect(Airbrake).to receive(:notify_or_ignore) do |error, opts|
          expect(error[:error_message]).to eq("Error validating payload against schema 'foo'")
          expect(opts[:parameters][:errors][0]).to match(
            a_hash_including(
              message: a_string_starting_with("The property '#/' of type Hash did not match"),
              failed_attribute: "OneOf",
              errors: {
                oneof_0: {
                  0 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'title'"),
                    failed_attribute: "Required",
                  ),
                },
                oneof_1: {
                  0 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'document_type'"),
                    failed_attribute: "Required",
                  ),
                  1 => a_hash_including(
                    message: a_string_starting_with("The property '#/' did not contain a required property of 'schema_name'"),
                    failed_attribute: "Required",
                  ),
                  2 => a_hash_including(
                    message: a_string_starting_with("The property '#/' contains additional properties [\"format\"] outside of the schema when none are allowed"),
                    failed_attribute: "AdditionalProperties"
                  ),
                }
              }
            )
          )
        end
        validator.validate(payload)
      end
    end
  end
end
