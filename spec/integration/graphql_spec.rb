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

  describe "world index" do
    before do
      create(
        :live_edition,
        title: "Help and services around the world",
        base_path: "/world",
        document_type: "world_index",
        details:
        {
          "world_locations": [
            {
              "active": true,
              "analytics_identifier": "WL1",
              "content_id": "d3b7ba48-5027-4a98-a594-1108d205dc66",
              "iso2": "WL",
              "name": "Test World Location",
              "slug": "test-world-location",
              "updated_at": "2024-10-18T14:22:38.000+01:00",
            },
          ],
          "international_delegations": [
            {
              "active": false,
              "analytics_identifier": "WL2",
              "content_id": "f0313f16-e25c-4bfe-a0fc-e561833f705f",
              "iso2": "ID",
              "name": "Test International Delegation",
              "slug": "test-international-delegation",
              "updated_at": "2024-10-19T15:07:44.000+01:00",
            },
          ],
        },
      )
    end

    it "exposes world index specific fields in addition to generic edition fields" do
      post "/graphql", params: {
        query:
          "fragment worldLocationInfo on WorldLocation {
            active
            analyticsIdentifier
            contentId
            name
            slug
            updatedAt
          }

          {
            edition(basePath: \"/world\") {
              ... on WorldIndex {
                title

                worldLocations {
                  ...worldLocationInfo
                }

                internationalDelegations {
                  ...worldLocationInfo
                }
              }
            }
          }",
      }

      expected = {
        "data": {
          "edition": {
            "title": "Help and services around the world",
            "worldLocations": [
              {
                "active": true,
                "analyticsIdentifier": "WL1",
                "contentId": "d3b7ba48-5027-4a98-a594-1108d205dc66",
                "name": "Test World Location",
                "slug": "test-world-location",
                "updatedAt": "2024-10-18T14:22:38+01:00",
              },
            ],
            "internationalDelegations": [
              {
                "active": false,
                "analyticsIdentifier": "WL2",
                "contentId": "f0313f16-e25c-4bfe-a0fc-e561833f705f",
                "name": "Test International Delegation",
                "slug": "test-international-delegation",
                "updatedAt": "2024-10-19T15:07:44+01:00",
              },
            ],
          },

        },
      }.to_json

      expect(response.body).to eq(expected)
    end
  end
end
