RSpec.describe "Types::EditionType" do
  include GraphQL::Testing::Helpers

  describe "#withdrawn_notice" do
    let(:query) do
      <<~QUERY
        query($base_path: String!) {
          edition(base_path: $base_path) {
            ... on Edition {
              base_path

              withdrawn_notice {
                explanation
                withdrawn_at
              }
            }
          }
        }
      QUERY
    end

    context "when the edition is withdrawn" do
      it "returns a withdrawal notice" do
        edition = create(:withdrawn_unpublished_edition, explanation: "for testing", unpublished_at: "2024-10-28 17:00:00.000000000 +0000")
        expected = {
          "explanation" => "for testing",
          "withdrawn_at" => "2024-10-28T17:00:00Z",
        }

        result = PublishingApiSchema
          .execute(query, variables: { base_path: edition.base_path })
          .dig("data", "edition", "withdrawn_notice")

        expect(result).to eq(expected)
      end
    end

    context "when the edition is not withdrawn" do
      it "returns nil" do
        edition = create(:live_edition)

        result = PublishingApiSchema
          .execute(query, variables: { base_path: edition.base_path })
          .dig("data", "edition", "withdrawn_notice")

        expect(result).to be_nil
      end
    end

    context "when the query has requested the withdrawn_notice for a linked to edition" do
      let(:query) do
        <<~QUERY
          query($base_path: String!) {
            edition(base_path: $base_path) {
              ... on Edition {
                base_path

                links {
                  role {
                    base_path
                    withdrawn_notice {
                      explanation
                      withdrawn_at
                    }
                  }
                }
              }
            }
          }
        QUERY
      end

      it "returns nil" do
        root_edition = create(:live_edition)
        linked_to_edition = create(
          :withdrawn_unpublished_edition,
          base_path: "/government/ministers/prime-minister",
        )
        create(
          :link_set,
          content_id: root_edition.content_id,
          links_hash: { role: [linked_to_edition.content_id] },
        )

        result = PublishingApiSchema
          .execute(query, variables: { base_path: root_edition.base_path })
          .dig("data", "edition", "links", "role")

        expect(result).to eq([{
          "base_path" => "/government/ministers/prime-minister",
          "withdrawn_notice" => nil,
        }])
      end
    end
  end

  context "content types in the details" do
    context "when the body is a string" do
      it "returns the string" do
        edition = create(:edition, details: { body: "some text" })

        expect(
          run_graphql_field(
            PublishingApiSchema,
            "Edition.details",
            edition,
            lookahead: OpenStruct.new(selections: [OpenStruct.new(name: :body)]),
          )[:body],
        ).to eq("some text")
      end
    end

    context "when there are multiple content types and one is html" do
      it "returns the html" do
        edition = create(:edition, details: {
          body: [
            { content_type: "text/govspeak", content: "some text" },
            { content_type: "text/html", content: "<p>some other text</p>" },
          ],
        })

        expect(
          run_graphql_field(
            PublishingApiSchema,
            "Edition.details",
            edition,
            lookahead: OpenStruct.new(selections: [OpenStruct.new(name: :body)]),
          )[:body],
        ).to eq("<p>some other text</p>")
      end
    end

    context "when there are multiple content types and none are html" do
      it "converts the govspeak to html" do
        edition = create(:edition, details: {
          body: [
            { content_type: "text/govspeak", content: "some text" },
          ],
        })

        expect(
          run_graphql_field(
            PublishingApiSchema,
            "Edition.details",
            edition,
            lookahead: OpenStruct.new(selections: [OpenStruct.new(name: :body)]),
          )[:body],
        ).to eq("<p>some text</p>\n")
      end
    end
  end
end
