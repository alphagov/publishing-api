RSpec.describe "Types::QueryType" do
  describe "EDITION_TYPES" do
    it "includes all EditionType descendants" do
      Rails.application.eager_load!

      expected = [Types::EditionType, *Types::EditionType.descendants]

      expect(Types::QueryType::EDITION_TYPES.sort).to eq(expected.sort)
    end
  end
end
