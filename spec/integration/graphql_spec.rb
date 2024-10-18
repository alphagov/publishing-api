RSpec.describe "GraphQL" do
  describe "generic edition" do
    before do
      create(:edition, title: "My Generic Edition", content_store: "live", base_path: "/my/generic/edition")
    end

    it "exposes generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(basePath: \"/my/generic/edition\") {
              title
            }
          }",
      }

      expected = {
        "data": {
          "edition": {
            "title": "My Generic Edition",
          },
        },
      }.to_json

      expect(response.body).to eq(expected)
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
        :edition,
        title: "Help and services around the world",
        content_store: "live",
        base_path: "/world",
        details:
        {
          "world_locations": [
            {
              "iso2": nil,
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
              "iso2": nil,
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
