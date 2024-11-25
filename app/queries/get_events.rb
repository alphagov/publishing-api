module Queries
  class GetEvents
    def self.call(content_id:, action: nil, from: nil, to: nil)
      new(content_id, action, from, to).call
    end

    def call
      result = Event.where(**query)
      result = result.where("created_at >= ?", from) if from.present?
      result = result.where("created_at <= ?", to) if to.present?

      result
    end

  private

    attr_reader :content_id, :action, :from, :to

    def query
      { content_id:, action: }.compact_blank!
    end

    def initialize(content_id, action, from, to)
      @content_id = content_id
      @action = action
      @from = from
      @to = to
    end
  end
end
