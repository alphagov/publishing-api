RSpec.describe "GraphQL" do
  let(:world_index_document) do
    create(
      :document,
      content_id: "369729ba-7776-4123-96be-2e3e98e153e1",
      editions: [
        create(
          :edition,
          title: "Help and services around the world",
          content_store: "live",
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
        ),
      ],
    )
  end

  describe "requesting fields" do
    before { world_index_document }

    it "only returns the requested fields" do
      post "/graphql", params: {
        query:
          "query worldIndex {
            worldIndex {
              title
            }
          }",
      }

      expected = {
        "data": {
          "worldIndex": {
            "title": "Help and services around the world",
          },
        },
      }.to_json

      expect(response.body).to eq(expected)
    end

    it "returns an error with when requesting unrecognised fields" do
      post "/graphql", params: {
        query:
          "query worldIndex {
            worldIndex {
              notAField
            }
          }",
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to match(
        {
          errors: [
            hash_including(
              message: "Field 'notAField' doesn't exist on type 'WorldIndex'",
            ),
          ],
        },
      )
    end
  end

  describe "world index" do
    before { world_index_document }

    let(:query) do
      "fragment worldLocationInfo on WorldLocation {
        active
        name
        slug
      }

      query worldIndex {
        worldIndex {
          title

          worldLocations {
            ...worldLocationInfo
          }

          internationalDelegations {
            ...worldLocationInfo
          }
        }
      }"
    end

    it "returns the required data and nothing more" do
      post "/graphql", params: { query: }

      expected = {
        "data": {
          "worldIndex": {
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
