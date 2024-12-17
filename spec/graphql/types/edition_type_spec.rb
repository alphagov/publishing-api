RSpec.describe "Types::EditionType" do
  include GraphQL::Testing::Helpers.for(PublishingApiSchema)

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
            "Edition.withdrawn_notice",
            create(:edition),
          ),
        ).to be_nil
      end
    end
  end
end
