RSpec.describe "GraphQL" do
  describe "generic edition" do
    before do
      document = create(:document, content_id: "d53db33f-d4ac-4eb3-839a-d415174eb906")
      @edition = create(:live_edition, document:, base_path: "/my/generic/edition")
    end

    it "exposes generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(basePath: \"/my/generic/edition\") {
              analyticsIdentifier
              basePath
              contentId
              description
              details
              documentType
              firstPublishedAt
              links
              locale
              phase
              publicUpdatedAt
              publishingApp
              publishingRequestId
              publishingScheduledAt
              renderingApp
              scheduledPublishingDelaySeconds
              schemaName
              title
              updatedAt
              withdrawnNotice {
                explanation
                withdrawnAt
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
            "details": @edition.details.to_s,
            "documentType": @edition.document_type,
            "firstPublishedAt": @edition.first_published_at.iso8601,
            "links": [],
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
            "withdrawnNotice": {
              "explanation": nil,
              "withdrawnAt": nil,
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "does not expose non-generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(basePath: \"/my/generic/edition\") {
              worldLocations {
                active
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
        details:
        {
          "world_locations": [
            {
              "iso2": "WL",
              "name": "Test World Location",
              "slug": "test-world-location",
              "active": true,
              "content_id": "d3b7ba48-5027-4a98-a594-1108d205dc66",
              "updated_at": "2024-10-18T14:22:38.000+01:00",
              "analytics_identifier": "WL1",
            },
          ],
          "international_delegations": [
            {
              "iso2": "ID",
              "name": "Test International Delegation",
              "slug": "test-international-delegation",
              "active": false,
              "content_id": "f0313f16-e25c-4bfe-a0fc-e561833f705f",
              "updated_at": "2024-10-18T14:22:38.000+01:00",
              "analytics_identifier": "WL2",
            },
          ],
        },
      )
    end

    it "returns the required data and nothing more" do
      post "/graphql", params: {
        query:
          "fragment worldLocationInfo on WorldLocation {
            active
            name
            slug
          }

          {
            edition(basePath: \"/world\") {
              title

              worldLocations {
                ...worldLocationInfo
              }

              internationalDelegations {
                ...worldLocationInfo
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
                "name": "Test World Location",
                "slug": "test-world-location",
              },
            ],
            "internationalDelegations": [
              {
                "active": false,
                "name": "Test International Delegation",
                "slug": "test-international-delegation",
              },
            ],
          },

        },
      }.to_json

      expect(response.body).to eq(expected)
    end
  end
end
