RSpec.describe "Types::EditionType" do
  include GraphQL::Testing::Helpers

  describe "#withdrawn_notice" do
    context "when the edition is withdrawn" do
      it "returns a withdrawal notice" do
        edition = create(:withdrawn_unpublished_edition, explanation: "for testing", unpublished_at: "2024-10-28 17:00:00.000000000 +0000")
        expected = {
          explanation: "for testing",
          withdrawn_at: "2024-10-28T17:00:00Z",
        }

        expect(
          run_graphql_field(
            PublishingApiSchema,
            "Edition.withdrawn_notice",
            edition,
          ),
        ).to eq(expected)
      end
    end

    context "when the edition is not withdrawn" do
      it "returns nil" do
        expect(
          run_graphql_field(
            PublishingApiSchema,
            "Edition.withdrawn_notice",
            create(:edition),
          ),
        ).to be_nil
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
