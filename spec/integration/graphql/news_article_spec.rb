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
                base_path: "/government/news/announcement",
                content_store: "live",
              ) {
                ... on NewsArticle {
                  base_path
                  title
                  details
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
                      title
                    }
                    people {
                      base_path
                      title
                    }
                    taxons {
                      base_path
                      content_id
                      title
                      links {
                        parent_taxons {
                          base_path
                          content_id
                          title
                        }
                      }
                    }
                    topical_events {
                      base_path
                      title
                    }
                    world_locations {
                      base_path
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
            base_path: @edition.base_path,
            details: {
              body: @edition.details[:body],
            },
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
                    current: @government.details["current"],
                  },
                  title: @government.title,
                },
              ],
              organisations: [
                {
                  base_path: @organisation.base_path,
                  title: @organisation.title,
                },
              ],
              people: [
                {
                  base_path: @person.base_path,
                  title: @person.title,
                },
              ],
              taxons: [
                {
                  base_path: @child_taxon.base_path,
                  content_id: @child_taxon.content_id,
                  title: @child_taxon.title,
                  links: {
                    parent_taxons: [
                      {
                        base_path: @parent_taxon.base_path,
                        content_id: @parent_taxon.content_id,
                        title: @parent_taxon.title,
                      },
                    ],
                  },
                },
              ],
              topical_events: [
                {
                  base_path: @topical_event.base_path,
                  title: @topical_event.title,
                },
              ],
              world_locations: [
                {
                  base_path: @world_location.base_path,
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
