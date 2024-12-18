RSpec.describe Types::QueryType do
  include GraphQL::Testing::Helpers.for(PublishingApiSchema)

  describe "#edition" do
    let(:query) do
      <<~QUERY
        query($base_path: String!, $content_store: String!) {
          edition(base_path: $base_path, content_store: $content_store) {
            ... on Edition {
              base_path
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
            "base_path" => draft_edition.base_path,
            "state" => "draft",
          }

          result = PublishingApiSchema.execute(query, variables: { base_path: draft_edition.base_path, content_store: "draft" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting the live edition" do
        it "returns no edition" do
          result = PublishingApiSchema.execute(query, variables: { base_path: draft_edition.base_path, content_store: "live" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to be_nil
        end
      end
    end

    context "when there is only a live edition" do
      let(:live_edition) { create(:live_edition) }

      context "requesting the draft edition" do
        it "returns no edition" do
          result = PublishingApiSchema.execute(query, variables: { base_path: live_edition.base_path, content_store: "draft" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to be_nil
        end
      end

      context "requesting the live edition" do
        it "returns the live edition" do
          expected_data = {
            "base_path" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(query, variables: { base_path: live_edition.base_path, content_store: "live" })
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
            "base_path" => draft_edition.base_path,
            "state" => "draft",
          }

          result = PublishingApiSchema.execute(query, variables: { base_path: draft_edition.base_path, content_store: "draft" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting the live edition" do
        it "returns the live edition" do
          expected_data = {
            "base_path" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(query, variables: { base_path: live_edition.base_path, content_store: "live" })
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end
    end
  end
end
