module Queries
  module GetContent
    def self.call(content_id, locale = nil, version: nil, include_warnings: false)
      locale_to_use = locale || ContentItem::DEFAULT_LOCALE

      content_items = ContentItem.where(content_id: content_id)
      content_items = Translation.filter(content_items, locale: locale_to_use)
      content_items = UserFacingVersion.filter(content_items, number: version) if version

      response = Presenters::Queries::ContentItemPresenter.present_many(
        content_items,
        include_warnings: include_warnings
      ).first

      if response.present?
        response
      else
        message = not_found_message(content_id, locale, version)
        raise_not_found(message)
      end
    end

    def self.raise_not_found(message)
      error_details = {
        error: {
          code: 404,
          message: message
        }
      }

      raise CommandError.new(code: 404, error_details: error_details)
    end

    def self.not_found_message(content_id, locale, version)
      if (locale || version) && ContentItem.exists?(content_id: content_id)
        locale_message = locale ? "locale: #{locale}" : nil
        version_message = version ? "version: #{version}" : nil
        reason = [locale_message, version_message].compact.join(" and ")

        "Could not find #{reason} for content item with content_id: #{content_id}"
      else
        "Could not find content item with content_id: #{content_id}"
      end
    end
    private_class_method :raise_not_found, :not_found_message
  end
end
