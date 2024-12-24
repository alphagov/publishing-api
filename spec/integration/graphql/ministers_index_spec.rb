RSpec.describe "GraphQL" do
  include MinistersIndexHelpers

  describe "ministers index" do
    let(:index_page_link_set) do
      index_page = create(
        :live_edition,
        title: "Ministers Index",
        document_type: "ministers_index",
        base_path: "/government/ministers",
        details: {
          body: [
            {
              content: "Never gonna give you up",
              content_type: "text/govspeak",
            },
          ],
        },
      )

      create(:link_set, content_id: index_page.content_id)
    end

    def uuid_matcher
      /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/
    end

    def make_request
      post "/graphql", params: {
        query:
        "{
          edition(base_path: \"/government/ministers\") {
            ... on MinistersIndex {
              base_path

              links {
                ordered_cabinet_ministers {
                  ...basePersonInfo
                }

                ordered_also_attends_cabinet {
                  ...basePersonInfo
                }

                ordered_assistant_whips {
                  ...basePersonInfo
                }

                ordered_baronesses_and_lords_in_waiting_whips {
                  ...basePersonInfo
                }

                ordered_house_lords_whips {
                  ...basePersonInfo
                }

                ordered_house_of_commons_whips {
                  ...basePersonInfo
                }

                ordered_junior_lords_of_the_treasury_whips {
                  ...basePersonInfo
                }

                ordered_ministerial_departments {
                  title
                  web_url

                  details {
                    brand

                    logo {
                      crest
                      formatted_title
                    }
                  }

                  links {
                    ordered_ministers {
                      ...basePersonInfo
                    }

                    ordered_roles {
                      content_id
                    }
                  }
                }
              }
            }
          }
        }

        fragment basePersonInfo on MinistersIndexPerson {
          title
          base_path
          web_url

          details {
            privy_counsellor

            image {
              url
              alt_text
            }
          }

          links {
            role_appointments {
              details {
                current
              }

              links {
                role {
                  content_id
                  title
                  web_url

                  details {
                    role_payment_type
                    seniority
                    whip_organisation {
                      label
                      sort_order
                    }
                  }
                }
              }
            }
          }
        }",
      }
    end

    def parsed_response
      JSON.parse(response.body).deep_symbolize_keys
    end

    def parsed_links
      parsed_response.dig(:data, :edition, :links)
    end

    it "exposes Ministers Index fields and its links" do
      create_index_page

      make_request

      expect(parsed_response).to match({
        data: {
          edition: {
            base_path: "/government/ministers",
            links: be_kind_of(Hash),
          },
        },
      })

      expect(parsed_links.keys).to match(%i[
        ordered_cabinet_ministers
        ordered_also_attends_cabinet
        ordered_assistant_whips
        ordered_baronesses_and_lords_in_waiting_whips
        ordered_house_lords_whips
        ordered_house_of_commons_whips
        ordered_junior_lords_of_the_treasury_whips
        ordered_ministerial_departments
      ])
    end

    describe "ordered_cabinet_ministers links" do
      before do
        person1 = create_person_with_role_appointment("Keir Starmer 1", "1st Minister")
        extra_role = create_role("First Lord of The Treasury")
        appoint_person_to_role(person1, extra_role)
        add_link(person1, link_type: "ordered_cabinet_ministers", link_set: index_page_link_set, position: 0)

        person3 = create_person_with_role_appointment("Keir Starmer 3", "3rd Minister")
        add_link(person3, link_type: "ordered_cabinet_ministers", link_set: index_page_link_set, position: 2)

        person2 = create_person_with_role_appointment("Keir Starmer 2", "2nd Minister")
        add_link(person2, link_type: "ordered_cabinet_ministers", link_set: index_page_link_set, position: 1)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_cabinet_ministers)).to match([
          {
            base_path: "/government/people/keir-starmer-1",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/keir-starmer-1.jpg",
                alt_text: "Keir Starmer 1",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "1st Minister",
                        web_url: "http://www.dev.gov.uk/government/ministers/1st-minister",
                      },
                    ],
                  },
                },
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "First Lord of The Treasury",
                        web_url: "http://www.dev.gov.uk/government/ministers/first-lord-of-the-treasury",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Keir Starmer 1",
            web_url: "http://www.dev.gov.uk/government/people/keir-starmer-1",
          },
          {
            base_path: "/government/people/keir-starmer-2",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/keir-starmer-2.jpg",
                alt_text: "Keir Starmer 2",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "2nd Minister",
                        web_url: "http://www.dev.gov.uk/government/ministers/2nd-minister",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Keir Starmer 2",
            web_url: "http://www.dev.gov.uk/government/people/keir-starmer-2",
          },
          {
            base_path: "/government/people/keir-starmer-3",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/keir-starmer-3.jpg",
                alt_text: "Keir Starmer 3",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "3rd Minister",
                        web_url: "http://www.dev.gov.uk/government/ministers/3rd-minister",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Keir Starmer 3",
            web_url: "http://www.dev.gov.uk/government/people/keir-starmer-3",
          },
        ])
      end
    end

    describe "orderedAlsoAttendsCabinet links" do
      before do
        person = create_person_with_role_appointment(
          "Alan Campbell",
          "Parliamentary Secretary to the Treasury (Chief Whip)",
        )
        add_link(person, link_type: "ordered_also_attends_cabinet", link_set: index_page_link_set)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_also_attends_cabinet)).to match([
          {
            base_path: "/government/people/alan-campbell",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/alan-campbell.jpg",
                alt_text: "Alan Campbell",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "Parliamentary Secretary to the Treasury (Chief Whip)",
                        web_url: "http://www.dev.gov.uk/government/ministers/parliamentary-secretary-to-the-treasury-chief-whip",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Alan Campbell",
            web_url: "http://www.dev.gov.uk/government/people/alan-campbell",
          },
        ])
      end
    end

    describe "orderedAssistantWhips links" do
      before do
        person = create_person("Christian Wakeford MP")
        role = create_role(
          "Assistant Whip, House of Commons",
          whip_organisation: {
            label: "Assistant Whips",
            sort_order: 3,
          },
        )
        appoint_person_to_role(person, role)
        add_link(person, link_type: "ordered_assistant_whips", link_set: index_page_link_set)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_assistant_whips)).to match([
          {
            base_path: "/government/people/christian-wakeford-mp",
            details: {
              image: {
                alt_text: "Christian Wakeford MP",
                url: "http://assets.dev.gov.uk/media/christian-wakeford-mp.jpg",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: {
                            label: "Assistant Whips",
                            sort_order: 3,
                          },
                        },
                        title: "Assistant Whip, House of Commons",
                        web_url: "http://www.dev.gov.uk/government/ministers/assistant-whip-house-of-commons",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Christian Wakeford MP",
            web_url: "http://www.dev.gov.uk/government/people/christian-wakeford-mp",
          },
        ])
      end
    end

    describe "orderedBaronessesAndLordsInWaitingWhips links" do
      before do
        person = create_person("Lord Cryer")
        role = create_role("Lord in Waiting", role_payment_type: "Unpaid")
        appoint_person_to_role(person, role)
        add_link(person, link_type: "ordered_baronesses_and_lords_in_waiting_whips", link_set: index_page_link_set)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_baronesses_and_lords_in_waiting_whips)).to match([
          {
            base_path: "/government/people/lord-cryer",
            details: {
              image: {
                alt_text: "Lord Cryer",
                url: "http://assets.dev.gov.uk/media/lord-cryer.jpg",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: "Unpaid",
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "Lord in Waiting",
                        web_url: "http://www.dev.gov.uk/government/ministers/lord-in-waiting",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Lord Cryer",
            web_url: "http://www.dev.gov.uk/government/people/lord-cryer",
          },
        ])
      end
    end

    describe "orderedHouseLordsWhips links" do
      before do
        person = create_person_with_role_appointment(
          "Baroness Wheeler MBE",
          "Captain of The King’s Bodyguard of the Yeoman of the Guard",
        )
        add_link(person, link_type: "ordered_house_lords_whips", link_set: index_page_link_set)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_house_lords_whips)).to match([
          {
            base_path: "/government/people/baroness-wheeler-mbe",
            details: {
              image: {
                alt_text: "Baroness Wheeler MBE",
                url: "http://assets.dev.gov.uk/media/baroness-wheeler-mbe.jpg",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "Captain of The King’s Bodyguard of the Yeoman of the Guard",
                        web_url: "http://www.dev.gov.uk/government/ministers/captain-of-the-king-s-bodyguard-of-the-yeoman-of-the-guard",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Baroness Wheeler MBE",
            web_url: "http://www.dev.gov.uk/government/people/baroness-wheeler-mbe",
          },
        ])
      end
    end

    describe "orderedHouseOfCommonsWhips links" do
      before do
        person = create_person_with_role_appointment(
          "Samantha Dixon MP",
          "Vice Chamberlain of HM Household",
        )
        add_link(person, link_type: "ordered_house_of_commons_whips", link_set: index_page_link_set)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_house_of_commons_whips)).to match([
          {
            base_path: "/government/people/samantha-dixon-mp",
            details: {
              image: {
                alt_text: "Samantha Dixon MP",
                url: "http://assets.dev.gov.uk/media/samantha-dixon-mp.jpg",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "Vice Chamberlain of HM Household",
                        web_url: "http://www.dev.gov.uk/government/ministers/vice-chamberlain-of-hm-household",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Samantha Dixon MP",
            web_url: "http://www.dev.gov.uk/government/people/samantha-dixon-mp",
          },
        ])
      end
    end

    describe "orderedJuniorLordsOfTheTreasuryWhips links" do
      before do
        person = create_person_with_role_appointment(
          "Vicky Foxcroft MP",
          "Junior Lord of the Treasury (Government Whip)",
        )
        add_link(person, link_type: "ordered_junior_lords_of_the_treasury_whips", link_set: index_page_link_set)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_junior_lords_of_the_treasury_whips)).to match([
          {
            base_path: "/government/people/vicky-foxcroft-mp",
            details: {
              image: {
                alt_text: "Vicky Foxcroft MP",
                url: "http://assets.dev.gov.uk/media/vicky-foxcroft-mp.jpg",
              },
              privy_counsellor: nil,
            },
            links: {
              role_appointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        content_id: uuid_matcher,
                        details: {
                          role_payment_type: nil,
                          seniority: 100,
                          whip_organisation: nil,
                        },
                        title: "Junior Lord of the Treasury (Government Whip)",
                        web_url: "http://www.dev.gov.uk/government/ministers/junior-lord-of-the-treasury-government-whip",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Vicky Foxcroft MP",
            web_url: "http://www.dev.gov.uk/government/people/vicky-foxcroft-mp",
          },
        ])
      end
    end

    describe "orderedMinisterialDepartments links" do
      before do
        cabinet_office = create_organisation("Cabinet Office")
        add_link(cabinet_office, link_type: "ordered_ministerial_departments", link_set: index_page_link_set)

        person = create_person("Keir Starmer")
        role = create_role("Prime Minister")
        appoint_person_to_role(person, role)

        extra_role = create_role("First Lord of The Treasury")
        appoint_person_to_role(person, extra_role)

        add_department_link(cabinet_office, person, link_type: "ordered_ministers")

        add_department_link(cabinet_office, role, link_type: "ordered_roles")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:ordered_ministerial_departments)).to match([
          {
            details: {
              brand: nil,
              logo: nil,
            },
            links: {
              ordered_ministers: [
                {
                  base_path: "/government/people/keir-starmer",
                  details: {
                    image: {
                      alt_text: "Keir Starmer",
                      url: "http://assets.dev.gov.uk/media/keir-starmer.jpg",
                    },
                    privy_counsellor: nil,
                  },
                  links: {
                    role_appointments: [
                      {
                        details: { current: true },
                        links: {
                          role: [
                            {
                              content_id: uuid_matcher,
                              details: {
                                role_payment_type: nil,
                                seniority: 100,
                                whip_organisation: nil,
                              },
                              title: "Prime Minister",
                              web_url: "http://www.dev.gov.uk/government/ministers/prime-minister",
                            },
                          ],
                        },
                      },
                      {
                        details: { current: true },
                        links: {
                          role: [
                            {
                              content_id: uuid_matcher,
                              details: {
                                role_payment_type: nil,
                                seniority: 100,
                                whip_organisation: nil,
                              },
                              title: "First Lord of The Treasury",
                              web_url: "http://www.dev.gov.uk/government/ministers/first-lord-of-the-treasury",
                            },
                          ],
                        },
                      },
                    ],
                  },
                  title: "Keir Starmer",
                  web_url: "http://www.dev.gov.uk/government/people/keir-starmer",
                },
              ],
              ordered_roles: [
                {
                  content_id: uuid_matcher,
                },
              ],
            },
            title: "Cabinet Office",
            web_url: "http://www.dev.gov.uk/government/organisations/cabinet-office",
          },
        ])
      end
    end
  end

  def create_index_page
    index_page_link_set # invoke `let`
  end
end
