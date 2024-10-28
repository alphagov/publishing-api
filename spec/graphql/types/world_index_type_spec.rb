RSpec.describe "Types::WorldIndexType" do
  describe ".base_path" do
    it "defines a base path for .resolve_type to distinguish the type from the generic Edition type" do
      expect(Types::WorldIndexType.base_path).to eq("/world")
    end
  end
end
