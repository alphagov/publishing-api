# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  skip_before_action :authenticate_user!, only: [:execute]

  def content
    execute_in_read_replica do
      query = case find_schema_name(base_path)
      when :news_article
        news_article_query(base_path:)
      when :ministers_index
        ministers_index_query
      when :role
        role_query(base_path:)
      when :world_index
        world_index_query
      end
      result = PublishingApiSchema.execute(query).to_hash

      process_graphql_result(result)

      # what would be really good here is responding with 404s and the like
      render json: result.dig("data", "edition")
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end
  end

  def execute
    execute_in_read_replica do
      variables = prepare_variables(params[:variables])
      query = params[:query]
      operation_name = params[:operationName]
      context = {
        # Query context goes here, for example:
        # current_user: current_user,
      }
      result = PublishingApiSchema.execute(
        query,
        variables:,
        context:,
        operation_name:,
      ).to_hash

      process_graphql_result(result)

      render json: result
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end
  end

private

  def base_path
    "/#{params[:path_without_root]}"
  end

  def find_schema_name(base_path)
    if base_path == "/government/ministers"
      :ministers_index
    elsif base_path == "/world"
      :world_index
    else
      Edition.live.where(base_path:).pick(:schema_name)&.to_sym
    end
  end

  def process_graphql_result(result)
    set_prometheus_labels(result.dig("data", "edition")&.slice("document_type", "schema_name"))

    if result.key?("errors")
      logger.warn("GraphQL query result contained errors: #{result['errors']}")
      set_prometheus_labels("contains_errors" => true)
    else
      logger.debug("GraphQL query result: #{result}")
      set_prometheus_labels("contains_errors" => false)
    end
  end

  def execute_in_read_replica(&block)
    if Rails.env.production_replica?
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        yield block
      end
    else
      yield block
    end
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: { errors: [{ message: error.message, backtrace: error.backtrace }], data: {} }, status: :internal_server_error
  end

  def set_prometheus_labels(hash)
    return unless hash

    prometheus_labels = request.env.fetch("govuk.prometheus_labels", {})

    request.env["govuk.prometheus_labels"] = prometheus_labels.merge(hash)
  end

  def ministers_index_query
    <<-QUERY
      {
        edition(base_path: "/government/ministers") {
          ... on MinistersIndex {
            base_path
            content_id
            document_type
            first_published_at
            locale
            public_updated_at
            publishing_app
            rendering_app
            schema_name
            updated_at

            details {
              body
              reshuffle
            }

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
      }
    QUERY
  end

  def news_article_query(base_path:)
    <<-QUERY
        {
          edition(
            base_path: "#{base_path}",
            content_store: "live",
          ) {
            ... on Edition {
              base_path
              content_id
              description
              details {
                body
                change_history
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
                document_collections {
                  ...RelatedItem
                  web_url
                }
                government {
                  details {
                    current
                  }
                  title
                }
                mainstream_browse_pages {
                  ...RelatedItem
                }
                ordered_related_items {
                  ...RelatedItem
                  links {
                    mainstream_browse_pages {
                      links {
                        parent {
                          title
                        }
                      }
                    }
                  }
                }
                ordered_related_items_overrides {
                  ...RelatedItem
                }
                organisations {
                  analytics_identifier
                  base_path
                  content_id
                  title
                }
                people {
                  base_path
                  content_id
                  title
                }
                primary_publishing_organisation {
                  base_path
                  details {
                    default_news_image {
                      alt_text
                      url
                    }
                  }
                  title
                }
                related {
                  ...RelatedItem
                }
                related_guides {
                  ...RelatedItem
                }
                related_mainstream_content {
                  ...RelatedItem
                }
                related_statistical_data_sets {
                  ...RelatedItem
                }
                suggested_ordered_related_items {
                  ...RelatedItem
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
                  ...RelatedItem
                  content_id
                }
                world_locations {
                  analytics_identifier
                  base_path
                  content_id
                  locale
                  title
                }
                worldwide_organisations {
                  analytics_identifier
                  base_path
                  title
                }
              }
              locale
              public_updated_at
              publishing_app
              rendering_app
              schema_name
              title
              updated_at
              withdrawn_notice {
                explanation
                withdrawn_at
              }
            }
          }
        }

        fragment RelatedItem on Edition {
          base_path
          document_type
          locale
          title
        }

        fragment Taxon on Edition {
          base_path
          content_id
          details {
            url_override
          }
          document_type
          locale
          phase
          title
          web_url
        }
    QUERY
  end

  def role_query(base_path:)
    <<-QUERY
      {
        edition(base_path: "#{base_path}") {
          ... on Edition {
            base_path
            content_id
            document_type
            first_published_at
            locale
            public_updated_at
            publishing_app
            rendering_app
            schema_name
            title
            updated_at

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
                analytics_identifier
                base_path
                title
              }

              organisations {
                analytics_identifier
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
            }
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
  end

  def world_index_query
    <<-QUERY
      fragment worldLocationInfo on Edition {
        active
        name
        slug
      }

      {
        edition(base_path: "/world") {
          ... on Edition {
            content_id
            document_type
            first_published_at
            locale
            public_updated_at
            publishing_app
            rendering_app
            schema_name
            title
            updated_at

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
      }
    QUERY
  end
end
