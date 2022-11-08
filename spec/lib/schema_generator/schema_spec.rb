require "spec_helper"
require "schema_generator/schema"

RSpec.describe SchemaGenerator::Schema do
  describe ".ordered_schema" do
    subject(:ordered_schema) { described_class.ordered_schema(schema_hash) }

    context "when provided with a json schema hash" do
      let(:schema_hash) do
        {
          "$ref" => "http://www.example.com",
          "type" => "object",
          "definitions" => [],
          "description" => "My description",
          "required" => [],
          "properties" => {},
        }
      end

      let(:expected_ordering) do
        %w[
          description
          $ref
          type
          required
          properties
          definitions
        ]
      end

      it "orders the schema" do
        expect(ordered_schema.keys).to eq expected_ordering
      end
    end

    context "when there are fields inside a properties object" do
      let(:schema_hash) do
        {
          "properties" => {
            "z" => 1,
            "a" => 2,
            "_" => 3,
          },
        }
      end

      let(:expected_ordering) { %w[_ a z] }

      it "orders the property alphabetically" do
        expect(ordered_schema["properties"].keys).to eq expected_ordering
      end
    end

    context "when a nested object is given" do
      let(:schema_hash) do
        {
          "type" => "object",
          "description" => "My object",
          "nested" => {
            "type" => "object",
            "description" => "My object",
            "nested" => {},
          },
        }
      end

      let(:expected_ordering) { %w[description type nested] }

      it "orders the nested object" do
        expect(ordered_schema.keys).to eq expected_ordering
        expect(ordered_schema["nested"].keys).to eq expected_ordering
      end
    end
  end
end
