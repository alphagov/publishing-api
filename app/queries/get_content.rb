module Queries
  module GetContent
    def self.call(content_id, locale = nil, version: nil, include_warnings: false)
      locale_to_use = locale || Edition::DEFAULT_LOCALE

      editions = Edition.with_document
        .where(documents: { content_id:, locale: locale_to_use })

      editions = editions.where(user_facing_version: version) if version

      response = Presenters::Queries::ContentItemPresenter.present_many(
        editions,
        include_warnings:,
        states: %i[draft published unpublished superseded],
      ).first

      if response.present?
        response
      else
        message = not_found_message(content_id, locale_to_use, version)
        raise_not_found(message)
      end
    end

    def self.raise_not_found(message)
      raise CommandError.new(code: 404, message:)
    end

    def self.not_found_message(content_id, locale, version)
      if Document.exists?(content_id:)
        locale_message = "locale: #{locale}"
        version_message = version ? "version: #{version}" : nil
        reason = [locale_message, version_message].compact.join(" and ")

        "Could not find #{reason} for document with content_id: #{content_id}"
      else
        "Could not find document with content_id: #{content_id}"
      end
    end
    private_class_method :raise_not_found, :not_found_message
  end
end
