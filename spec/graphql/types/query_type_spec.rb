RSpec.describe Types::QueryType do
  include GraphQL::Testing::Helpers.for(PublishingApiSchema)

  describe "#edition" do
    let(:query) do
      <<~QUERY
        query($base_path: String!, $with_drafts: Boolean!) {
          edition(base_path: $base_path, with_drafts: $with_drafts) {
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

      context "requesting with_drafts=true" do
        it "returns the draft edition" do
          expected_data = {
            "base_path" => draft_edition.base_path,
            "state" => "draft",
          }

          result = PublishingApiSchema.execute(
            query,
            variables: {
              base_path: draft_edition.base_path,
              with_drafts: true,
            },
          )
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting with_drafts=false" do
        it "returns no edition" do
          result = PublishingApiSchema.execute(
            query,
            variables: {
              base_path: draft_edition.base_path,
              with_drafts: false,
            },
          )
          edition_data = result.dig("data", "edition")
          expect(edition_data).to be_nil
        end
      end
    end

    context "when there is only a live edition" do
      let(:live_edition) { create(:live_edition) }

      context "requesting with_drafts=true" do
        it "returns the live edition" do
          expected_data = {
            "base_path" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(
            query,
            variables: {
              base_path: live_edition.base_path,
              with_drafts: true,
            },
          )
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting with_drafts=false" do
        it "returns the live edition" do
          expected_data = {
            "base_path" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(
            query,
            variables: {
              base_path: live_edition.base_path,
              with_drafts: false,
            },
          )
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

      context "requesting with_drafts=true" do
        it "returns the draft edition" do
          expected_data = {
            "base_path" => draft_edition.base_path,
            "state" => "draft",
          }

          result = PublishingApiSchema.execute(
            query,
            variables: {
              base_path: live_edition.base_path,
              with_drafts: true,
            },
          )
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end

      context "requesting with_drafts=false" do
        it "returns the live edition" do
          expected_data = {
            "base_path" => live_edition.base_path,
            "state" => "published",
          }

          result = PublishingApiSchema.execute(
            query,
            variables: {
              base_path: live_edition.base_path,
              with_drafts: false,
            },
          )
          edition_data = result.dig("data", "edition")
          expect(edition_data).to eq(expected_data)
        end
      end
    end
  end
end
