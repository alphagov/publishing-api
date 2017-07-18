module Presenters
  module GetEditionsPresenter
    def self.present(query, request_url)
      results = KeysetPaginationPresenter.new(query, request_url).present

      results[:results] = results[:results].map do |record|
        record.except("id", "document_id")
      end

      results
    end
  end
end
