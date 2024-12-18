RSpec.describe "GraphQL" do
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
            analytics_identifier
            content_id
            name
            slug
            updated_at
          }

          {
            edition(base_path: \"/world\") {
              ... on WorldIndex {
                title

                details {
                  world_locations {
                    ...worldLocationInfo
                  }

                  international_delegations {
                    ...worldLocationInfo
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            title: "Help and services around the world",
            details: {
              world_locations: [
                {
                  active: true,
                  analytics_identifier: "WL1",
                  content_id: "d3b7ba48-5027-4a98-a594-1108d205dc66",
                  name: "Test World Location",
                  slug: "test-world-location",
                  updated_at: "2024-10-18T14:22:38+01:00",
                },
              ],
              international_delegations: [
                {
                  active: false,
                  analytics_identifier: "WL2",
                  content_id: "f0313f16-e25c-4bfe-a0fc-e561833f705f",
                  name: "Test International Delegation",
                  slug: "test-international-delegation",
                  updated_at: "2024-10-19T15:07:44+01:00",
                },
              ],
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys
      expect(parsed_response).to eq(expected)
    end
  end
end
