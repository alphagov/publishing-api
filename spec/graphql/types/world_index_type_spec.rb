RSpec.describe "Types::WorldIndexType" do
  describe ".document_type" do
    it "defines a document type for .resolve_type to distinguish the type from the generic Edition type" do
      expect(Types::WorldIndexType.document_type).to eq("world_index")
    end
  end
end
