module Queries
  class GetLinkChanges
    # Current maximum number of results. This is an arbitrary number to prevent
    # too much data being returned, and to hold off from implementing pagination.
    MAXIMUM_NUMBER_OF_RESULTS = 250

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def as_hash
      results = link_changes.map do |link_change|
        {
          source: expand_edition(link_change.source_content_id),
          target: expand_edition(link_change.target_content_id),
          link_type: link_change.link_type,
          change: link_change.change,
          user_uid: link_change.action.user_uid,
          created_at: link_change.created_at,
        }
      end

      {
        link_changes: SymbolizeJSON.symbolize(results),
      }
    end

  private

    def expand_edition(content_id)
      editions = all_related_editions[content_id]
      editions && editions.first.slice(%w[title base_path content_id])
    end

    def link_changes
      @link_changes ||= LinkChange
                          .order(created_at: :desc)
                          .where(where_query_from_params)
                          .limit(MAXIMUM_NUMBER_OF_RESULTS)
                          .includes(:action)
    end

    def where_query_from_params
      # Link type is required. Calling `fetch` on a Rails parameters object
      # will bubble up to the controller to return a 4XX response.
      query = { link_type: params.fetch(:link_types) }

      if params[:source_content_ids]
        query[:source_content_id] = params[:source_content_ids]
      end

      if params[:target_content_ids]
        query[:target_content_id] = params[:target_content_ids]
      end

      if params[:users]
        query["actions.user_uid"] = params[:users]
      end

      query
    end

    # Returns all editions (with their document) that are either the source or
    # the target of the link change.
    def all_related_editions
      @all_related_editions ||= begin
        content_ids_relevant = (
          link_changes.map(&:source_content_id) +
          link_changes.map(&:target_content_id)
        ).uniq

        Queries::GetLatest.call(
          Edition
            .eager_load(:document)
            .where("documents.content_id IN (?)", content_ids_relevant),
        ).group_by(&:content_id)
      end
    end
  end
end
