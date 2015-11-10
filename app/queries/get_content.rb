module Queries
  module GetContent
    def self.call(content_id, locale = nil)
      locale ||= DraftContentItem::DEFAULT_LOCALE

      content_item = DraftContentItem.find_by(
        content_id: content_id,
        locale: locale
      )

      if content_item
        Presenters::Queries::ContentItemPresenter.present(content_item)
      else
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
end
