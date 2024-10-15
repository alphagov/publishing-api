require "spec_helper"

RSpec.describe SchemaGenerator::Format::DocumentType do
  let!(:schema_filename) { "specialist_document" }
  let!(:data) { Jsonnet.load("content_schemas/formats/#{schema_filename}.jsonnet") }
  let!(:format) { SchemaGenerator::Format.new("specialist_document", data) }

  it "returns custom definition for specialist documents" do
    expect(format.document_type.definition).to eq({ "type" => "string" })
  end
end
