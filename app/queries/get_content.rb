module Queries
  module GetContent
    def self.call(content_id, locale = nil, version: nil, include_warnings: false, content_store: nil)
      raise CommandError.new(code: 422, message: "version parameter no longer supported in get_content") if version

      locale_to_use = locale || Edition::DEFAULT_LOCALE

      editions = Edition.with_document
        .where(documents: { content_id:, locale: locale_to_use })

      editions = editions.where(content_store:) if content_store

      response = Presenters::Queries::ContentItemPresenter.present_many(editions, include_warnings:).first

      if response.present?
        response
      else
        message = not_found_message(content_id, locale_to_use)
        raise_not_found(message)
      end
    end

    def self.raise_not_found(message)
      raise CommandError.new(code: 404, message:)
    end

    def self.not_found_message(content_id, locale)
      if Document.exists?(content_id:)
        "Could not find locale: #{locale} for document with content_id: #{content_id}"
      else
        "Could not find document with content_id: #{content_id}"
      end
    end
    private_class_method :raise_not_found, :not_found_message
  end
end
