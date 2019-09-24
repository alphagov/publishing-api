module Presenters
  class ResultsPresenter
    def initialize(results, pagination, request_url)
      @results = results.call
      @total = results.total
      @pagination = pagination
      @request_url = request_url.to_s
    end

    def present
      {
        total: total,
        pages: pagination_pages,
        current_page: current_page,
        links: links,
        results: results,
      }
    end

  private

    attr_reader :results, :pagination, :request_url, :total

    def current_page
      pagination.page.to_i
    end

    def pagination_pages
      pagination.pages(total)
    end

    def links
      [previous_link, next_link, self_link].compact
    end

    def previous_link
      return unless previous_page?

      {
        href: page_href(-1),
        rel: "previous",
      }
    end

    def next_link
      return unless next_page?

      {
        href: page_href(1),
        rel: "next",
      }
    end

    def self_link
      {
        href: page_href(0),
        rel: "self",
      }
    end

    def page_href(offset)
      request_url.gsub(/&page=(\d*)/, "") << "&page=#{current_page + offset}"
    end

    def previous_page?
      current_page > 1
    end

    def next_page?
      current_page < pagination_pages
    end
  end
end
