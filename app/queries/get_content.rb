module Queries
  module GetContent
    def self.call(content_id, locale = nil)
      locale ||= ContentItem::DEFAULT_LOCALE

      content_items = ContentItem.where(content_id: content_id)
      content_items = Translation.filter(content_items, locale: locale)
      content_items = State.filter(content_items, name: %w(draft published))

      response = Presenters::Queries::ContentItemPresenter.present_many(content_items).first

      if response.present?
        response
      else
        raise_not_found(content_id)
      end
    end

  private

    def self.raise_not_found(content_id)
      error_details = {
        error: {
          code: 404,
          message: "Could not find content item with content_id: #{content_id}"
        }
      }

      raise CommandError.new(code: 404, error_details: error_details)
    end
  end
end
