class Queries::Graphql::TopicalEventQuery
  def self.query(base_path:)
    <<~QUERY
      {
        edition(base_path: "#{base_path}") {
          ... on Edition {
            analytics_identifier
              base_path
              content_id
              description
              details {
                body
                emphasised_organisations
                end_date
                ordered_featured_documents
                social_media_links
                start_date
              }
              document_type
              first_published_at
              links {
                available_translations {
                  api_path
                  api_url
                  base_path
                  content_id
                  document_type
                  locale
                  public_updated_at
                  schema_name
                  title
                  web_url
                  withdrawn
                }
                organisations {
                  analytics_identifier
                  api_path
                  api_url
                  base_path
                  content_id
                  details {
                    acronym
                    brand
                    default_news_image {
                      alt_text
                      url
                    }
                    logo {
                      crest
                      formatted_title
                    }
                    organisation_govuk_status
                  }
                  document_type
                  locale
                  schema_name
                  title
                  web_url
                  withdrawn
                }
                primary_publishing_organisation {
                  analytics_identifier
                  api_path
                  api_url
                  base_path
                  content_id
                  details {
                    acronym
                    brand
                    default_news_image {
                      alt_text
                      url
                    }
                    logo {
                      crest
                      formatted_title
                    }
                    organisation_govuk_status
                  }
                  document_type
                  locale
                  schema_name
                  title
                  web_url
                  withdrawn
                }
              }
              locale
              phase
              public_updated_at
              publishing_app
              publishing_request_id
              publishing_scheduled_at
              rendering_app
              scheduled_publishing_delay_seconds
              schema_name
              title
              updated_at
              }
            }
      }
    QUERY
  end
end
