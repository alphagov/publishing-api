RSpec.describe "GraphQL" do
  describe "news article" do
    before do
      @edition = create(
        :live_edition,
        title: "Generic news article",
        base_path: "/government/news/announcement",
        document_type: "news_story",
        details: {
          body: "Some text",
        },
      )

      @government = create(
        :live_edition,
        document_type: "government",
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
                basePath: "/government/news/announcement",
                contentStore: "live",
              ) {
                ... on NewsArticle {
                  basePath
                  title
                  details
                  links {
                    availableTranslations {
                      basePath
                      locale
                    }
                    government {
                      details {
                        current
                      }
                      title
                    }
                    organisations {
                      basePath
                      title
                    }
                    people {
                      basePath
                      title
                    }
                    taxons {
                      basePath
                      contentId
                      title
                      links {
                        parentTaxons {
                          basePath
                          contentId
                          title
                        }
                      }
                    }
                    topicalEvents {
                      basePath
                      title
                    }
                    worldLocations {
                      basePath
                      title
                    }
                  }
                }
            }
          }
        QUERY
      }

      expected = {
        data: {
          edition: {
            basePath: @edition.base_path,
            details: {
              body: @edition.details[:body],
            },
            links: {
              availableTranslations: [
                {
                  basePath: @edition.base_path,
                  locale: @edition.locale,
                },
              ],
              government: [
                {
                  details: {
                    current: @government.details["current"],
                  },
                  title: @government.title,
                },
              ],
              organisations: [
                {
                  basePath: @organisation.base_path,
                  title: @organisation.title,
                },
              ],
              people: [
                {
                  basePath: @person.base_path,
                  title: @person.title,
                },
              ],
              taxons: [
                {
                  basePath: @child_taxon.base_path,
                  contentId: @child_taxon.content_id,
                  title: @child_taxon.title,
                  links: {
                    parentTaxons: [
                      {
                        basePath: @parent_taxon.base_path,
                        contentId: @parent_taxon.content_id,
                        title: @parent_taxon.title,
                      },
                    ],
                  },
                },
              ],
              topicalEvents: [
                {
                  basePath: @topical_event.base_path,
                  title: @topical_event.title,
                },
              ],
              worldLocations: [
                {
                  basePath: @world_location.base_path,
                  title: @world_location.title,
                },
              ],
            },
            title: @edition.title,
          },
        },
      }

      expect(JSON.parse(response.body).deep_symbolize_keys).to eq(expected)
    end
  end
end
