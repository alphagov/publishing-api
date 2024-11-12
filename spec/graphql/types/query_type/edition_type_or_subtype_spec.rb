RSpec.describe "Types::QueryType::EditionTypeOrSubtype" do
  describe "EDITION_TYPES" do
    it "includes all EditionType descendants" do
      Rails.application.eager_load!

      expected = [Types::EditionType, *Types::EditionType.descendants].map(&:name)
      actual = Types::QueryType::EditionTypeOrSubtype::EDITION_TYPES.map(&:name)
      diff = expected - actual

      expect(diff).to be_empty
    end
  end

  describe ".resolve_type" do
    context "when the object's `document_type` matches an Edition subtype's `document_type`" do
      it "returns the Edition subtype" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            build(:live_edition, document_type: "world_index"),
            {},
          ),
        ).to be Types::WorldIndexType
      end
    end

    context "when the object's `document_type` does not match an Edition subtype's `document_type`" do
      it "returns the generic Edition type" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            build(:live_edition, document_type: "a_generic_type"),
            {},
          ),
        ).to be Types::EditionType
      end
    end
  end
end
