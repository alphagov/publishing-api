RSpec.describe "Types::WorldIndexType" do
  describe ".base_path" do
    it "defines a base path to be referenced in Types::EditionTypes.visible?" do
      expect(Types::WorldIndexType.base_path).to eq("/world")
    end
  end
end
