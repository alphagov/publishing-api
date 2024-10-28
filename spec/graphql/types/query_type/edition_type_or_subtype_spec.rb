RSpec.describe "Types::QueryType::EditionTypeOrSubtype" do
  describe "EDITION_TYPES" do
    it "includes all EditionType descendants" do
      Rails.application.eager_load!

      expected = [Types::EditionType, *Types::EditionType.descendants]

      expect(Types::QueryType::EditionTypeOrSubtype::EDITION_TYPES.sort).to eq(expected.sort)
    end
  end

  describe ".resolve_type" do
    context "when the basePath argument matches an Edition subtype's base path" do
      it "returns the Edition subtype" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            {},
            mock_context(base_path_argument: "/world"),
          ),
        ).to be Types::WorldIndexType
      end
    end

    context "when the basePath argument does matches a base path of any Edition subtype" do
      it "returns the generic Edition type" do
        expect(
          Types::QueryType::EditionTypeOrSubtype.resolve_type(
            {},
            mock_context(base_path_argument: "/a/generic/edition"),
          ),
        ).to be Types::EditionType
      end
    end
  end

private

  def mock_context(base_path_argument:)
    JSON.parse({
      query: {
        lookahead: {
          ast_nodes: [{
            selections: [{
              arguments: [{
                name: "basePath",
                value: base_path_argument,
              }],
            }],
          }],
        },
      },
    }.to_json, object_class: OpenStruct)
  end
end
