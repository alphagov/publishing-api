module Queries
  class GetLinkChanges
    PAGE_LENGTH = 1000
    attr_reader :params

    def initialize(params)
      @params = params
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
        next_page_path: next_page_path
      }
    end

    def link_changes
      @link_changes ||= begin
        change_query = LinkChange.order(:id).limit(PAGE_LENGTH).includes(:action)
        change_query = change_query.where("ID >= ?", params[:start]) unless params[:start].nil?
        change_query
      end
    end

    def next_page_path
      if link_changes.count == PAGE_LENGTH
        "/v2/links/changes?start=#{link_changes.last.id + 1}"
      end
    end
  end
end
