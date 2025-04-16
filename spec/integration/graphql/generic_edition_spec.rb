RSpec.describe "GraphQL" do
  describe "generic edition" do
    before do
      document = create(:document, content_id: "d53db33f-d4ac-4eb3-839a-d415174eb906")
      @edition = create(
        :live_edition,
        document:,
        document_type: "generic_type",
        base_path: "/my/generic/edition",
        first_published_at: Time.utc(2025, 1, 1, 0, 0, 0),
        public_updated_at: Time.utc(2025, 4, 1, 0, 0, 0),
        updated_at: Time.utc(2025, 4, 1, 0, 0, 0),
      )
    end

    it "exposes generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"/my/generic/edition\") {
              ... on Edition {
                title
                analytics_identifier
                base_path
                content_id
                description
                details {
                  body
                }
                document_type
                first_published_at
                locale
                phase
                public_updated_at
                publishing_app
                publishing_request_id
                publishing_scheduled_at
                rendering_app
                scheduled_publishing_delay_seconds
                schema_name
                updated_at
                withdrawn_notice {
                  explanation
                  withdrawn_at
                }
              }
            }
          }",
      }

      expected = {
        "data": {
          "edition": {
            "analytics_identifier": @edition.analytics_identifier,
            "base_path": @edition.base_path,
            "content_id": @edition.content_id,
            "description": @edition.description,
            "details": {
              "body": @edition.details[:body],
            },
            "document_type": @edition.document_type,
            "first_published_at": "2025-01-01T00:00:00+00:00",
            "locale": @edition.locale,
            "phase": @edition.phase,
            "public_updated_at": "2025-04-01T01:00:00+01:00",
            "publishing_app": @edition.publishing_app,
            "publishing_request_id": @edition.publishing_request_id,
            "publishing_scheduled_at": nil,
            "rendering_app": @edition.rendering_app,
            "scheduled_publishing_delay_seconds": nil,
            "schema_name": @edition.schema_name,
            "title": @edition.title,
            "updated_at": "2025-04-01T01:00:00+01:00",
            "withdrawn_notice": nil,
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "sets the document type as a prometheus label" do
      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"/my/generic/edition\") {
              ... on Edition {
                title
                document_type
                schema_name
              }
            }
          }",
      }

      expect(request.env["govuk.prometheus_labels"][:document_type]).to eq(@edition.document_type)
      expect(request.env["govuk.prometheus_labels"][:schema_name]).to eq(@edition.schema_name)
    end

    context "when there is a withdrawn notice" do
      before do
        create(
          :withdrawn_unpublished_edition,
          base_path: "/my/withdrawn/edition",
          explanation: "for integration testing",
          document_type: "generic_type",
          unpublished_at: Time.utc(2024, 10, 28, 17, 0, 0),
        )
      end

      it "populates the withdrawn notice" do
        post "/graphql", params: {
          query:
            "{
              edition(base_path: \"/my/withdrawn/edition\") {
                ... on Edition {
                  withdrawn_notice {
                    explanation
                    withdrawn_at
                  }
                }
              }
            }",
        }

        expected = {
          "data": {
            "edition": {
              "withdrawn_notice": {
                "explanation": "for integration testing",
                "withdrawn_at": "2024-10-28T17:00:00+00:00",
              },
            },
          },
        }

        parsed_response = JSON.parse(response.body).deep_symbolize_keys

        expect(parsed_response).to eq(expected)
      end
    end
  end
end
