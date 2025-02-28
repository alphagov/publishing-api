RSpec.describe "Types::BaseObject" do
  describe "ALL_EDITION_COLUMNS" do
    it "is an up-to-date list of the Edition model's database columns" do
      expect(Types::BaseObject::ALL_EDITION_COLUMNS).to match_array(
        Edition.attribute_names.map(&:to_sym),
      )
    end
  end
end
