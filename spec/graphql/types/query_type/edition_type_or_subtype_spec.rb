RSpec.describe "Types::QueryType::EditionTypeOrSubtype" do
  describe "EDITION_TYPES" do
    it "includes all EditionType descendants that have a value for `relevant_schemas_and_document_types`" do
      Rails.application.eager_load!

      expected_subtypes = [*Types::EditionType.descendants]
        .select { |type| type.respond_to?(:relevant_schemas_and_document_types) }
      expected = [Types::EditionType] + expected_subtypes
      actual = Types::QueryType::EditionTypeOrSubtype::EDITION_TYPES

      expect(actual).to eq(expected)
    end
  end

  describe ".resolve_type" do
    context "when the object's `schema_name` and `document_type` matches an Edition subtype" do
      it "returns the Edition subtype" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            build(:live_edition, schema_name: "ministers_index", document_type: "ministers_index"),
            {},
          ),
        ).to be Types::MinistersIndexType
      end
    end

    context "when the object's `schema_name` matches but document_type` does not match an Edition subtype" do
      it "returns the generic Edition type" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            build(:live_edition, schema_name: "ministers_index", document_type: "a_generic_type"),
            {},
          ),
        ).to be Types::EditionType
      end
    end

    context "when the object's `schema_name` and document_type` do not match an Edition subtype" do
      it "returns the generic Edition type" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            build(:live_edition, schema_name: "generic", document_type: "a_generic_type"),
            {},
          ),
        ).to be Types::EditionType
      end
    end
  end
end
