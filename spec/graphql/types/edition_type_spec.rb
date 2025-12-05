RSpec.describe "Types::EditionType" do
  include GraphQL::Testing::Helpers

  describe "available_translations links" do
    it "returns available_translations as Editions" do
      content_id = SecureRandom.uuid
      edition = create(
        :live_edition,
        base_path: "/a",
        document: create(:document, locale: "en", content_id:),
      )
      create(
        :live_edition,
        base_path: "/a.ar",
        document: create(:document, locale: "ar", content_id:),
      )
      create(
        :live_edition,
        base_path: "/a.es",
        document: create(:document, locale: "es", content_id:),
      )

      expect(
        run_graphql_field(
          PublishingApiSchema,
          "Edition.links.available_translations",
          edition,
        ),
      ).to match_array([
        have_attributes(
          class: Edition,
          base_path: "/a",
          locale: "en",
          web_url: "http://www.dev.gov.uk/a",
        ),
        have_attributes(
          class: Edition,
          base_path: "/a.ar",
          locale: "ar",
          web_url: "http://www.dev.gov.uk/a.ar",
        ),
        have_attributes(
          class: Edition,
          base_path: "/a.es",
          locale: "es",
          web_url: "http://www.dev.gov.uk/a.es",
        ),
      ])
    end
  end

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
      it "raises a NotFoundError" do
        edition = create(:edition, details: {
          body: [
            { content_type: "text/govspeak", content: "some text" },
          ],
        })

        expect {
          run_graphql_field(
            PublishingApiSchema,
            "Edition.details",
            edition,
            lookahead: OpenStruct.new(selections: [OpenStruct.new(name: :body)]),
          )
        }.to raise_error(Presenters::ContentTypeResolver::NotFoundError)
      end
    end
  end
end
