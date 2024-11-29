RSpec.describe "GraphQL" do
  describe "generic edition" do
    before do
      document = create(:document, content_id: "d53db33f-d4ac-4eb3-839a-d415174eb906")
      @edition = create(:live_edition, document:, document_type: "generic_type", base_path: "/my/generic/edition")
    end

    it "exposes generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(basePath: \"/my/generic/edition\") {
              ... on Edition {
                title
                analyticsIdentifier
                basePath
                contentId
                description
                details
                documentType
                firstPublishedAt
                locale
                phase
                publicUpdatedAt
                publishingApp
                publishingRequestId
                publishingScheduledAt
                renderingApp
                scheduledPublishingDelaySeconds
                schemaName
                updatedAt
                withdrawnNotice {
                  explanation
                  withdrawnAt
                }
              }
            }
          }",
      }

      expected = {
        "data": {
          "edition": {
            "analyticsIdentifier": @edition.analytics_identifier,
            "basePath": @edition.base_path,
            "contentId": @edition.content_id,
            "description": @edition.description,
            "details": @edition.details,
            "documentType": @edition.document_type,
            "firstPublishedAt": @edition.first_published_at.iso8601,
            "locale": @edition.locale,
            "phase": @edition.phase,
            "publicUpdatedAt": @edition.public_updated_at.iso8601,
            "publishingApp": @edition.publishing_app,
            "publishingRequestId": @edition.publishing_request_id,
            "publishingScheduledAt": nil,
            "renderingApp": @edition.rendering_app,
            "scheduledPublishingDelaySeconds": nil,
            "schemaName": @edition.schema_name,
            "title": @edition.title,
            "updatedAt": @edition.updated_at.iso8601,
            "withdrawnNotice": nil,
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    context "when there is a withdrawn notice" do
      before do
        create(
          :withdrawn_unpublished_edition,
          base_path: "/my/withdrawn/edition",
          explanation: "for integration testing",
          document_type: "generic_type",
          unpublished_at: "2024-10-27 17:00:00.000000000 +0000",
        )
      end

      it "populates the withdrawn notice" do
        post "/graphql", params: {
          query:
            "{
              edition(basePath: \"/my/withdrawn/edition\") {
                ... on Edition {
                  withdrawnNotice {
                    explanation
                    withdrawnAt
                  }
                }
              }
            }",
        }

        expected = {
          "data": {
            "edition": {
              "withdrawnNotice": {
                "explanation": "for integration testing",
                "withdrawnAt": "2024-10-27T17:00:00Z",
              },
            },
          },
        }

        parsed_response = JSON.parse(response.body).deep_symbolize_keys

        expect(parsed_response).to eq(expected)
      end
    end

    it "does not expose non-generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(basePath: \"/my/generic/edition\") {
              ... on Edition {
                worldLocations {
                  active
                }
              }
            }
          }",
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to match(
        {
          errors: [
            hash_including(
              message: "Field 'worldLocations' doesn't exist on type 'Edition'",
            ),
          ],
        },
      )
    end
  end
end
