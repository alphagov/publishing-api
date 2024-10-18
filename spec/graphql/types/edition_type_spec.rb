RSpec.describe "Types::EditionType" do
  describe ".visible?" do
    before do
      Rails.application.eager_load!
    end

    context "when called by the EditionType" do
      context "and the basePath argument matches any descendants' base paths" do
        it "returns false, meaning GraphQL will check descendants for a match" do
          expect(Types::EditionType.visible?(mock_context(base_path_argument: "/world"))).to be false
        end
      end

      context "and the basePath argument does not match any descendents' base paths" do
        it "returns true, meaning the top-level EditionType's fields will be queryable" do
          expect(Types::EditionType.visible?(mock_context(base_path_argument: "/a/generic/edition"))).to be true
        end
      end
    end

    context "when called on a descendant of the EditionType" do
      context "and the basePath argument matches the descendant's base path" do
        it "returns true, meaning the descendant's fields will be queryable" do
          expect(Types::WorldIndexType.visible?(mock_context(base_path_argument: "/world"))).to be true
        end
      end

      context "and the basePath argument does not match the descendant's base path" do
        it "returns false, meaning GraphQL will check other types for a match" do
          expect(Types::WorldIndexType.visible?(mock_context(base_path_argument: "/a/generic/type"))).to be false
        end
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
