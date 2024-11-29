RSpec.describe "GraphQL" do
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
          edition(basePath: \"/government/ministers\") {
            ... on MinistersIndex {
              basePath

              links {
                orderedCabinetMinisters {
                  ...basePersonInfo
                }

                orderedAlsoAttendsCabinet {
                  ...basePersonInfo
                }

                orderedAssistantWhips {
                  ...basePersonInfo
                }

                orderedBaronessesAndLordsInWaitingWhips {
                  ...basePersonInfo
                }

                orderedHouseLordsWhips {
                  ...basePersonInfo
                }

                orderedHouseOfCommonsWhips {
                  ...basePersonInfo
                }

                orderedJuniorLordsOfTheTreasuryWhips {
                  ...basePersonInfo
                }

                orderedMinisterialDepartments {
                  title
                  webUrl

                  details {
                    brand

                    logo {
                      crest
                      formattedTitle
                    }
                  }

                  links {
                    orderedMinisters {
                      ...basePersonInfo
                    }

                    orderedRoles {
                      contentId
                    }
                  }
                }
              }
            }
          }
        }

        fragment basePersonInfo on MinistersIndexPerson {
          title
          basePath
          webUrl

          details {
            privyCounsellor

            image {
              url
              altText
            }
          }

          links {
            roleAppointments {
              details {
                current
              }

              links {
                role {
                  contentId
                  title
                  webUrl

                  details {
                    rolePaymentType
                    seniority
                    whipOrganisation {
                      label
                      sortOrder
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
            basePath: "/government/ministers",
            links: be_kind_of(Hash),
          },
        },
      })

      expect(parsed_links.keys).to match(%i[
        orderedCabinetMinisters
        orderedAlsoAttendsCabinet
        orderedAssistantWhips
        orderedBaronessesAndLordsInWaitingWhips
        orderedHouseLordsWhips
        orderedHouseOfCommonsWhips
        orderedJuniorLordsOfTheTreasuryWhips
        orderedMinisterialDepartments
      ])
    end

    describe "orderedCabinetMinisters links" do
      before do
        person1 = create_person_with_role_appointment("Keir Starmer 1", "1st Minister")
        extra_role = create_role("First Lord of The Treasury")
        appoint_person_to_role(person1, extra_role)
        add_link(person1, link_type: "ordered_cabinet_ministers", position: 0)

        person3 = create_person_with_role_appointment("Keir Starmer 3", "3rd Minister")
        add_link(person3, link_type: "ordered_cabinet_ministers", position: 2)

        person2 = create_person_with_role_appointment("Keir Starmer 2", "2nd Minister")
        add_link(person2, link_type: "ordered_cabinet_ministers", position: 1)
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedCabinetMinisters)).to match([
          {
            basePath: "/government/people/keir-starmer-1",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/keir-starmer-1.jpg",
                altText: "Keir Starmer 1",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "1st Minister",
                        webUrl: "http://www.dev.gov.uk/government/ministers/1st-minister",
                      },
                    ],
                  },
                },
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "First Lord of The Treasury",
                        webUrl: "http://www.dev.gov.uk/government/ministers/first-lord-of-the-treasury",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Keir Starmer 1",
            webUrl: "http://www.dev.gov.uk/government/people/keir-starmer-1",
          },
          {
            basePath: "/government/people/keir-starmer-2",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/keir-starmer-2.jpg",
                altText: "Keir Starmer 2",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "2nd Minister",
                        webUrl: "http://www.dev.gov.uk/government/ministers/2nd-minister",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Keir Starmer 2",
            webUrl: "http://www.dev.gov.uk/government/people/keir-starmer-2",
          },
          {
            basePath: "/government/people/keir-starmer-3",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/keir-starmer-3.jpg",
                altText: "Keir Starmer 3",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "3rd Minister",
                        webUrl: "http://www.dev.gov.uk/government/ministers/3rd-minister",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Keir Starmer 3",
            webUrl: "http://www.dev.gov.uk/government/people/keir-starmer-3",
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
        add_link(person, link_type: "ordered_also_attends_cabinet")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedAlsoAttendsCabinet)).to match([
          {
            basePath: "/government/people/alan-campbell",
            details: {
              image: {
                url: "http://assets.dev.gov.uk/media/alan-campbell.jpg",
                altText: "Alan Campbell",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "Parliamentary Secretary to the Treasury (Chief Whip)",
                        webUrl: "http://www.dev.gov.uk/government/ministers/parliamentary-secretary-to-the-treasury-chief-whip",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Alan Campbell",
            webUrl: "http://www.dev.gov.uk/government/people/alan-campbell",
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
        add_link(person, link_type: "ordered_assistant_whips")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedAssistantWhips)).to match([
          {
            basePath: "/government/people/christian-wakeford-mp",
            details: {
              image: {
                altText: "Christian Wakeford MP",
                url: "http://assets.dev.gov.uk/media/christian-wakeford-mp.jpg",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: {
                            label: "Assistant Whips",
                            sortOrder: 3,
                          },
                        },
                        title: "Assistant Whip, House of Commons",
                        webUrl: "http://www.dev.gov.uk/government/ministers/assistant-whip-house-of-commons",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Christian Wakeford MP",
            webUrl: "http://www.dev.gov.uk/government/people/christian-wakeford-mp",
          },
        ])
      end
    end

    describe "orderedBaronessesAndLordsInWaitingWhips links" do
      before do
        person = create_person("Lord Cryer")
        role = create_role("Lord in Waiting", role_payment_type: "Unpaid")
        appoint_person_to_role(person, role)
        add_link(person, link_type: "ordered_baronesses_and_lords_in_waiting_whips")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedBaronessesAndLordsInWaitingWhips)).to match([
          {
            basePath: "/government/people/lord-cryer",
            details: {
              image: {
                altText: "Lord Cryer",
                url: "http://assets.dev.gov.uk/media/lord-cryer.jpg",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: "Unpaid",
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "Lord in Waiting",
                        webUrl: "http://www.dev.gov.uk/government/ministers/lord-in-waiting",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Lord Cryer",
            webUrl: "http://www.dev.gov.uk/government/people/lord-cryer",
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
        add_link(person, link_type: "ordered_house_lords_whips")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedHouseLordsWhips)).to match([
          {
            basePath: "/government/people/baroness-wheeler-mbe",
            details: {
              image: {
                altText: "Baroness Wheeler MBE",
                url: "http://assets.dev.gov.uk/media/baroness-wheeler-mbe.jpg",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "Captain of The King’s Bodyguard of the Yeoman of the Guard",
                        webUrl: "http://www.dev.gov.uk/government/ministers/captain-of-the-king-s-bodyguard-of-the-yeoman-of-the-guard",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Baroness Wheeler MBE",
            webUrl: "http://www.dev.gov.uk/government/people/baroness-wheeler-mbe",
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
        add_link(person, link_type: "ordered_house_of_commons_whips")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedHouseOfCommonsWhips)).to match([
          {
            basePath: "/government/people/samantha-dixon-mp",
            details: {
              image: {
                altText: "Samantha Dixon MP",
                url: "http://assets.dev.gov.uk/media/samantha-dixon-mp.jpg",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "Vice Chamberlain of HM Household",
                        webUrl: "http://www.dev.gov.uk/government/ministers/vice-chamberlain-of-hm-household",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Samantha Dixon MP",
            webUrl: "http://www.dev.gov.uk/government/people/samantha-dixon-mp",
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
        add_link(person, link_type: "ordered_junior_lords_of_the_treasury_whips")
      end

      it "exposes the links' fields" do
        make_request

        expect(parsed_links.fetch(:orderedJuniorLordsOfTheTreasuryWhips)).to match([
          {
            basePath: "/government/people/vicky-foxcroft-mp",
            details: {
              image: {
                altText: "Vicky Foxcroft MP",
                url: "http://assets.dev.gov.uk/media/vicky-foxcroft-mp.jpg",
              },
              privyCounsellor: nil,
            },
            links: {
              roleAppointments: [
                {
                  details: { current: true },
                  links: {
                    role: [
                      {
                        contentId: uuid_matcher,
                        details: {
                          rolePaymentType: nil,
                          seniority: 100,
                          whipOrganisation: nil,
                        },
                        title: "Junior Lord of the Treasury (Government Whip)",
                        webUrl: "http://www.dev.gov.uk/government/ministers/junior-lord-of-the-treasury-government-whip",
                      },
                    ],
                  },
                },
              ],
            },
            title: "Vicky Foxcroft MP",
            webUrl: "http://www.dev.gov.uk/government/people/vicky-foxcroft-mp",
          },
        ])
      end
    end

    describe "orderedMinisterialDepartments links" do
      before do
        cabinet_office = create_organisation("Cabinet Office")
        add_link(cabinet_office, link_type: "ordered_ministerial_departments")

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

        expect(parsed_links.fetch(:orderedMinisterialDepartments)).to match([
          {
            details: {
              brand: nil,
              logo: nil,
            },
            links: {
              orderedMinisters: [
                {
                  basePath: "/government/people/keir-starmer",
                  details: {
                    image: {
                      altText: "Keir Starmer",
                      url: "http://assets.dev.gov.uk/media/keir-starmer.jpg",
                    },
                    privyCounsellor: nil,
                  },
                  links: {
                    roleAppointments: [
                      {
                        details: { current: true },
                        links: {
                          role: [
                            {
                              contentId: uuid_matcher,
                              details: {
                                rolePaymentType: nil,
                                seniority: 100,
                                whipOrganisation: nil,
                              },
                              title: "Prime Minister",
                              webUrl: "http://www.dev.gov.uk/government/ministers/prime-minister",
                            },
                          ],
                        },
                      },
                      {
                        details: { current: true },
                        links: {
                          role: [
                            {
                              contentId: uuid_matcher,
                              details: {
                                rolePaymentType: nil,
                                seniority: 100,
                                whipOrganisation: nil,
                              },
                              title: "First Lord of The Treasury",
                              webUrl: "http://www.dev.gov.uk/government/ministers/first-lord-of-the-treasury",
                            },
                          ],
                        },
                      },
                    ],
                  },
                  title: "Keir Starmer",
                  webUrl: "http://www.dev.gov.uk/government/people/keir-starmer",
                },
              ],
              orderedRoles: [
                {
                  contentId: uuid_matcher,
                },
              ],
            },
            title: "Cabinet Office",
            webUrl: "http://www.dev.gov.uk/government/organisations/cabinet-office",
          },
        ])
      end
    end
  end

  def create_index_page
    index_page_link_set # invoke `let`
  end

  def create_organisation(title)
    create(
      :live_edition,
      title:,
      document_type: "organisation",
      schema_name: "organisation",
      base_path: "/government/organisations/#{title.parameterize}",
    )
  end

  def create_role(title, role_payment_type: nil, whip_organisation: nil)
    create(
      :live_edition,
      title: title,
      document_type: "ministerial_role",
      base_path: "/government/ministers/#{title.parameterize}",
      details: {
        attends_cabinet_type: nil,
        body: [{
          content: "# #{title}\nThe #{title} is the #{title} of His Majesty's Government",
          content_type: "text/govspeak",
        }],
        supports_historical_accounts: true,
        role_payment_type:,
        seniority: 100,
        whip_organisation:,
      },
    )
  end

  def appoint_person_to_role(person, role)
    role_appointment = create(
      :live_edition,
      title: "#{person.title} - #{role.title}",
      document_type: "role_appointment",
      schema_name: "role_appointment",
      details: {
        current: true,
        started_on: Time.zone.local(2024, 7, 5),
      },
    )

    create(
      :link_set,
      content_id: role_appointment.content_id,
      links_hash: { person: [person.content_id], role: [role.content_id] },
    )
  end

  def create_person(title)
    create(
      :live_edition,
      title: title,
      document_type: "person",
      schema_name: "person",
      base_path: "/government/people/#{title.parameterize}",
      details: {
        body: [{
          content: "#{title} A Role on 5 July 2024.",
          content_type: "text/govspeak",
        }],
        image: {
          url: "http://assets.dev.gov.uk/media/#{title.parameterize}.jpg",
          alt_text: title,
        },
      },
    )
  end

  def create_person_with_role_appointment(person_title, role_title)
    person = create_person(person_title)
    role = create_role(role_title)
    appoint_person_to_role(person, role)

    person
  end

  def add_link(target_content, link_type:, position: 0)
    create(
      :link,
      position:,
      link_type:,
      link_set: index_page_link_set,
      target_content_id: target_content.content_id,
    )
  end

  def add_department_link(department, target_content, link_type:)
    link_set = LinkSet.find_or_create_by!(content_id: department.content_id)

    create(
      :link,
      link_type:,
      link_set:,
      target_content_id: target_content.content_id,
    )
  end
end
