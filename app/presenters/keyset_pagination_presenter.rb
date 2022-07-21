module Presenters
  class KeysetPaginationPresenter
    def initialize(pagination_query, request_url)
      @results = pagination_query.results
      @pagination_query = pagination_query
      @request_url = request_url.to_s
    end

    def present
      {
        links: links,
        results: presented_results,
      }
    end

  private

    attr_reader :results, :pagination_query, :request_url

    def presented_results
      results.map do |record|
        record.except(*fields_to_clear)
      end
    end

    def fields_to_clear
      pagination_query.key_fields - pagination_query.presented_fields
    end

    def links
      [next_link, self_link, previous_link].compact
    end

    def next_link
      { href: next_url, rel: "next" } unless pagination_query.is_last_page?
    end

    def self_link
      { href: self_url, rel: "self" }
    end

    def previous_link
      { href: previous_url, rel: "previous" } unless pagination_query.is_first_page?
    end

    def next_url
      page_href(after: pagination_query.next_after_key.join(","))
    end

    def previous_url
      page_href(before: pagination_query.next_before_key.join(","))
    end

    def self_url
      page_href
    end

    def page_href(before: nil, after: nil)
      except = before || after ? %w[before after] : []

      uri = URI.parse(request_url)

      new_params = Rack::Utils.parse_query(uri.query)
        .except(*except).merge({ before: before, after: after }.compact)

      new_query = Rack::Utils.build_query(new_params) unless new_params.empty?

      uri.query = new_query
      uri.to_s
    end
  end
end
