module Presenters
  class KeysetPaginationPresenter
    def initialize(pagination, request_url)
      @results = pagination.call.as_json
      @pagination = pagination
      @request_url = request_url.to_s
    end

    def present
      {
        links: links,
        results: results
      }
    end

  private

    attr_reader :results, :pagination, :request_url, :present_record_filter

    def links
      [next_link]
    end

    def next_link
      { href: next_url, rel: "next" }
    end

    def next_url
      page_href(pagination.key_for_record(results.last))
    end

    def page_href(page)
      uri = URI.parse(request_url)
      uri.query = Rack::Utils.build_query(
        Rack::Utils.parse_query(uri.query).except("page").merge(page: page)
      )
      uri.to_s
    end
  end
end
