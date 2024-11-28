RSpec.describe Types::QueryType do
  include GraphQL::Testing::Helpers.for(PublishingApiSchema)

  describe "#edition" do
    let(:query) do
      <<~QUERY
        query($basePath: String!, $contentStore: String!) {
          edition(basePath: $basePath, contentStore: $contentStore) {
            ... on Edition {
              basePath
              state
            }
          }
        }
      QUERY
    end

    context "when there is only a draft edition" do
      let(:draft_edition) { create(:draft_edition) }

      context "requesting the draft edition" do
        it "returns the draft edition" do
          expected_data = {
            "basePath" => draft_edition.base_path,
            "state" => "draft",
          }

          result = PublishingApiSchema.execute(query, variables: { basePath: draft_edition.base_path, contentStore: "draft" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting the live edition" do
        it "returns no edition" do
          result = PublishingApiSchema.execute(query, variables: { basePath: draft_edition.base_path, contentStore: "live" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to be_nil
        end
      end
    end

    context "when there is only a live edition" do
      let(:live_edition) { create(:live_edition) }

      context "requesting the draft edition" do
        it "returns no edition" do
          result = PublishingApiSchema.execute(query, variables: { basePath: live_edition.base_path, contentStore: "draft" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to be_nil
        end
      end

      context "requesting the live edition" do
        it "returns the live edition" do
          expected_data = {
            "basePath" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(query, variables: { basePath: live_edition.base_path, contentStore: "live" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end
    end

    context "when there is a published edition and a newer draft edition" do
      let(:document) { create(:document) }
      let(:base_path) { "/foo" }
      let!(:live_edition) { create(:live_edition, document:, base_path:, user_facing_version: 1) }
      let!(:draft_edition) { create(:draft_edition, document:, base_path:, user_facing_version: 2) }

      context "requesting the draft edition" do
        it "returns the draft edition" do
          expected_data = {
            "basePath" => draft_edition.base_path,
            "state" => "draft",
          }

          result = PublishingApiSchema.execute(query, variables: { basePath: draft_edition.base_path, contentStore: "draft" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting the live edition" do
        it "returns the live edition" do
          expected_data = {
            "basePath" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(query, variables: { basePath: live_edition.base_path, contentStore: "live" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end
    end
  end
end
