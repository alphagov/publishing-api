RSpec.describe "GraphQL" do
  describe "roles" do
    before do
      role = create(
        :live_edition,
        title: "Prime Minister",
        document_type: "ministerial_role",
        base_path: "/government/ministers/prime-minister",
        details:
        {
          "attends_cabinet_type": nil,
          "body": [{
            "content_type": "text/govspeak",
            "content": "# Prime Minister\nThe Prime Minister is the leader of His Majesty's Government",
          }],
          "supports_historical_accounts": true,
        },
      )
      create(
        :live_edition,
        title: "Prime Minister Español",
        document: create(:document, content_id: role.content_id, locale: "es"),
        document_type: "ministerial_role",
        base_path: "/government/ministers/prime-minister.es",
      )

      role_appointment1 = create(
        :live_edition,
        title: "The Rt Hon Keir Starmer - Prime Minister",
        document_type: "role_appointment",
        schema_name: "role_appointment",
        details: {
          current: true,
          started_on: Time.zone.local(2024, 7, 5),
        },
      ).tap do |role_appointment|
        person = create(
          :live_edition,
          title: "The Rt Hon Sir Keir Starmer KCB KC MP",
          document_type: "person",
          schema_name: "person",
          base_path: "/government/people/keir-starmer",
          details: {
            body: [{
              content: "Sir Keir Starmer became Prime Minister on 5 July 2024.",
              content_type: "text/govspeak",
            }],
          },
        )
        create(
          :link_set,
          content_id: role_appointment.content_id,
          links_hash: { person: [person.content_id], role: [role.content_id] },
        )
      end

      role_appointment2 = create(
        :live_edition,
        title: "The Rt Hon Rishi Sunak - Prime Minister",
        document_type: "role_appointment",
        schema_name: "role_appointment",
        details: {
          current: false,
          started_on: Time.zone.local(2022, 10, 25),
          ended_on: Time.zone.local(2024, 7, 5),
        },
      ).tap do |role_appointment|
        person = create(
          :live_edition,
          title: "The Rt Hon Rishi Sunak MP",
          document_type: "person",
          schema_name: "person",
          base_path: "/government/people/rishi-sunak",
          details: {
            body: [{
              content: "Rishi Sunak was Prime Minister between 25 October 2022 and 5 July 2024.",
              content_type: "text/govspeak",
            }],
          },
        )
        create(
          :link_set,
          content_id: role_appointment.content_id,
          links_hash: { person: [person.content_id], role: [role.content_id] },
        )
      end

      organisation1 = create(
        :live_edition,
        title: "Cabinet Office",
        document_type: "organisation",
        schema_name: "organisation",
        base_path: "/government/organisations/cabinet-office",
      )
      organisation2 = create(
        :live_edition,
        title: "Prime Minister's Office, 10 Downing Street",
        document_type: "organisation",
        schema_name: "organisation",
        base_path: "/government/organisations/prime-ministers-office-10-downing-street",
      )
      create(
        :link_set,
        content_id: role.content_id,
        links_hash: {
          ordered_parent_organisations: [organisation1.content_id, organisation2.content_id],
          role_appointments: [role_appointment1.content_id, role_appointment2.content_id],
        },
      )
    end

    it "exposes Role-specific fields, generic Edition fields and Role's links" do
      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"/government/ministers/prime-minister\") {
              ... on Role {
                base_path
                locale
                title

                details {
                  body
                  supports_historical_accounts
                }

                links {
                  available_translations {
                    base_path
                    locale
                  }

                  role_appointments {
                    details {
                      current
                      ended_on
                      started_on
                    }

                    links {
                      person {
                        base_path
                        title

                        details {
                          body
                        }
                      }
                    }
                  }

                  ordered_parent_organisations {
                    base_path
                    title
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            base_path: "/government/ministers/prime-minister",
            locale: "en",
            title: "Prime Minister",
            details: {
              body: "<h1 id=\"prime-minister\">Prime Minister</h1>\n<p>The Prime Minister is the leader of His Majesty’s Government</p>\n",
              supports_historical_accounts: true,
            },
            links: {
              available_translations: [
                {
                  base_path: "/government/ministers/prime-minister",
                  locale: "en",
                },
                {
                  base_path: "/government/ministers/prime-minister.es",
                  locale: "es",
                },
              ],
              role_appointments: [
                {
                  details: {
                    current: true,
                    ended_on: nil,
                    started_on: "2024-07-05T00:00:00Z",
                  },
                  links: {
                    person: [
                      base_path: "/government/people/keir-starmer",
                      title: "The Rt Hon Sir Keir Starmer KCB KC MP",
                      details: {
                        body: "<p>Sir Keir Starmer became Prime Minister on 5 July 2024.</p>\n",
                      },
                    ],
                  },
                },
                {
                  details: {
                    current: false,
                    ended_on: "2024-07-05T00:00:00Z",
                    started_on: "2022-10-25T00:00:00Z",
                  },
                  links: {
                    person: [
                      base_path: "/government/people/rishi-sunak",
                      details: {
                        body: "<p>Rishi Sunak was Prime Minister between 25 October 2022 and 5 July 2024.</p>\n",
                      },
                      title: "The Rt Hon Rishi Sunak MP",
                    ],
                  },
                },
              ],
              ordered_parent_organisations: [
                {
                  base_path: "/government/organisations/cabinet-office",
                  title: "Cabinet Office",
                },
                {
                  base_path: "/government/organisations/prime-ministers-office-10-downing-street",
                  title: "Prime Minister's Office, 10 Downing Street",
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
