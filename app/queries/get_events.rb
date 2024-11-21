module Queries
  class GetEvents
    def self.call(content_id:, action: nil)
      new(content_id, action).call
    end

    def call
      Event.where(**query)
    end

  private

    attr_reader :content_id, :action

    def query
      { content_id:, action: }.compact_blank!
    end

    def initialize(content_id, action)
      @content_id = content_id
      @action = action
    end
  end
end
