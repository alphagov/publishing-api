module Presenters
  class KeysetPaginationPresenter
    def initialize(pagination, request_url, present_record_filter: nil)
      @results = pagination.call.as_json
      @pagination = pagination
      @request_url = request_url.to_s
      @present_record_filter = present_record_filter
    end

    def present
      {
        links: links,
        results: presented_results
      }
    end

  private

    attr_reader :results, :pagination, :request_url, :present_record_filter

    def presented_results
      return ordered_results unless present_record_filter
      ordered_results.map do |record|
        present_record_filter.call(record)
      end
    end

    def ordered_results
      @ordered_results ||=
        pagination.presenter_should_reverse_results? ? results.reverse : results
    end

    def links
      [previous_link, next_link]
    end

    def previous_link
      { href: previous_url, rel: "previous" }
    end

    def next_link
      { href: next_url, rel: "next" }
    end

    def previous_url
      page_href(before: pagination.key_for_record(ordered_results.first))
    end

    def next_url
      page_href(after: pagination.key_for_record(ordered_results.last))
    end

    def page_href(parameters)
      uri = URI.parse(request_url)
      current_params = Rack::Utils.parse_query(uri.query)
      current_params.delete("before")
      current_params.delete("after")
      uri.query = Rack::Utils.build_query(
        current_params.merge(parameters)
      )
      uri.to_s
    end
  end
end
