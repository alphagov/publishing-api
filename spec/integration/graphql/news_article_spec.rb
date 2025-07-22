RSpec.describe "GraphQL" do
  describe "news article" do
    before do
      @edition = create(
        :live_edition,
        base_path: "/government/news/announcement",
        description: "My great description",
        details: {
          body: "Some text",
          change_history: [{ note: "Info", public_timestamp: "2025-01-01 00:01:00" }],
          default_news_image: {
            alt_text: "Some default alt text",
            url: "https://assets.publishing.service.gov.uk/media/30984dsfkjsdfkjh/s300_my_default_image.jpg",
          },
          display_date: "2025-03-23T10:45:00+00:00",
          emphasised_organisations: %w[6667cce2-e809-4e21-ae09-cb0bdc1ddda3],
          first_public_at: "2013-03-21T13:20:50+00:00",
          image: {
            alt_text: "Some alt text",
            caption: "Some caption",
            credit: "Some credit",
            high_resolution_url: "https://assets.publishing.service.gov.uk/media/324438lksdjalsdj/s960_my_lovely_hd_image.jpg",
            url: "https://assets.publishing.service.gov.uk/media/29843nksdfjhdsfj/s300_my_lovely_image.jpg",
          },
          political: false,
        },
        document_type: "news_story",
        schema_name: "news_article",
        title: "Generic news article",
      )

      @government = create(
        :live_edition,
        document_type: "government",
        details: {
          "current" => true,
        },
      )

      @organisation = create(
        :live_edition,
        document_type: "organisation",
      )

      @person = create(
        :live_edition,
        document_type: "person",
      )

      @topical_event = create(
        :live_edition,
        document_type: "topical_event",
      )

      @world_location = create(
        :live_edition,
        document_type: "world_location",
      )

      @parent_taxon = create(
        :live_edition,
        document_type: "taxon",
      )

      @child_taxon = create(
        :live_edition,
        document_type: "taxon",
      )

      create(:link_set,
             content_id: @child_taxon.document.content_id,
             links_hash: {
               parent_taxons: [
                 @parent_taxon.document.content_id,
               ],
             })

      create(:link_set,
             content_id: @edition.document.content_id,
             links_hash: {
               government: [
                 @government.document.content_id,
               ],
               organisations: [
                 @organisation.document.content_id,
               ],
               people: [
                 @person.document.content_id,
               ],
               taxons: [
                 @child_taxon.document.content_id,
               ],
               topical_events: [
                 @topical_event.document.content_id,
               ],
               world_locations: [
                 @world_location.document.content_id,
               ],
             })
    end

    it "exposes news article specific fields in addition to generic edition fields" do
      post "/graphql", params: {
        query: <<~QUERY,
          {
            edition(
              base_path: "/government/news/announcement",
              content_store: "live",
            ) {
              ... on Edition {
                base_path
                description
                details {
                  body
                  change_history
                  default_news_image {
                    alt_text
                    url
                  }
                  display_date
                  emphasised_organisations
                  first_public_at
                  image {
                    alt_text
                    caption
                    credit
                    high_resolution_url
                    url
                  }
                  political
                }
                document_type
                first_published_at
                links {
                  available_translations {
                    base_path
                    locale
                  }
                  government {
                    details {
                      current
                    }
                    title
                  }
                  organisations {
                    base_path
                    content_id
                    title
                  }
                  people {
                    base_path
                    content_id
                    title
                  }
                  taxons {
                    ...Taxon
                    links {
                      parent_taxons {
                        ...Taxon
                        links {
                          parent_taxons {
                            ...Taxon
                            links {
                              parent_taxons {
                                ...Taxon
                                links {
                                  parent_taxons {
                                    ...Taxon
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                  topical_events {
                    base_path
                    content_id
                    title
                  }
                  world_locations {
                    base_path
                    content_id
                    title
                  }
                }
                locale
                schema_name
                title
              }
            }
          }

          fragment Taxon on Edition {
            base_path
            content_id
            document_type
            phase
            title
          }
        QUERY
      }

      expected = {
        data: {
          edition: {
            base_path: @edition.base_path,
            description: @edition.description,
            details: {
              body: @edition.details[:body],
              change_history: [{ note: "Info", public_timestamp: "2025-01-01 00:01:00 UTC" }],
              default_news_image: @edition.details[:default_news_image],
              display_date: @edition.details[:display_date],
              emphasised_organisations: @edition.details[:emphasised_organisations],
              first_public_at: @edition.details[:first_public_at],
              image: @edition.details[:image],
              political: @edition.details[:political],
            },
            document_type: @edition.document_type,
            first_published_at: @edition.first_published_at.in_time_zone("Europe/London").iso8601,
            links: {
              available_translations: [
                {
                  base_path: @edition.base_path,
                  locale: @edition.locale,
                },
              ],
              government: [
                {
                  details: {
                    current: @government.details[:current],
                  },
                  title: @government.title,
                },
              ],
              organisations: [
                {
                  base_path: @organisation.base_path,
                  content_id: @organisation.content_id,
                  title: @organisation.title,
                },
              ],
              people: [
                {
                  base_path: @person.base_path,
                  content_id: @person.content_id,
                  title: @person.title,
                },
              ],
              taxons: [
                {
                  base_path: @child_taxon.base_path,
                  content_id: @child_taxon.content_id,
                  document_type: @child_taxon.document_type,
                  phase: @child_taxon.phase,
                  title: @child_taxon.title,
                  links: {
                    parent_taxons: [
                      {
                        base_path: @parent_taxon.base_path,
                        content_id: @parent_taxon.content_id,
                        document_type: @parent_taxon.document_type,
                        links: {
                          parent_taxons: [],
                        },
                        phase: @parent_taxon.phase,
                        title: @parent_taxon.title,
                      },
                    ],
                  },
                },
              ],
              topical_events: [
                {
                  base_path: @topical_event.base_path,
                  content_id: @topical_event.content_id,
                  title: @topical_event.title,
                },
              ],
              world_locations: [
                {
                  base_path: @world_location.base_path,
                  content_id: @world_location.content_id,
                  title: @world_location.title,
                },
              ],
            },
            locale: @edition.locale,
            schema_name: @edition.schema_name,
            title: @edition.title,
          },
        },
      }

      expect(JSON.parse(response.body).deep_symbolize_keys).to eq(expected)
    end
  end
end
