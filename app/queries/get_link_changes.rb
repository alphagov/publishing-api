module Queries
  class GetLinkChanges
    PAGE_LENGTH = 1000
    attr_reader :params, :request_url

    def initialize(params, request_url)
      @params = params
      @request_url = request_url
    end

    def as_json
      results = link_changes.map do |link_change|
        {
          id: link_change.id,
          source_content_id: link_change.source_content_id,
          target_content_id: link_change.target_content_id,
          link_type: link_change.link_type,
          change: link_change.change,
          user_uid: link_change.action.user_uid,
          created_at: link_change.created_at
        }
      end

      {
        link_changes: results,
        links: links,
      }
    end

  private

    def link_changes
      @link_changes ||= begin
        change_query = LinkChange.order(:id).limit(PAGE_LENGTH).includes(:action)
        change_query = change_query.where("ID >= ?", params[:start]) unless params[:start].nil?
        change_query
      end
    end

    def links
      if link_changes.count == PAGE_LENGTH
        [{ href: page_href(start: link_changes.last.id + 1), rel: "next" }]
      else
        []
      end
    end

    def page_href(start:)
      uri = URI.parse(request_url)
      new_params = Rack::Utils.parse_query(uri.query).merge(start: start)
      new_query = Rack::Utils.build_query(new_params)
      uri.query = new_query
      uri.to_s
    end
  end
end
