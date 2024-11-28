RSpec.describe "Types::WorldIndexType" do
  describe ".document_types" do
    it "defines the document types for .resolve_type to distinguish the type from the generic Edition type" do
      expect(Types::WorldIndexType.document_types).to eq(%w[world_index])
    end
  end
end
