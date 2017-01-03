module Queries
  module GetDocument
    def self.call(content_id, locale = nil, version: nil, include_warnings: false)
      locale_to_use = locale || ContentItem::DEFAULT_LOCALE

      begin
        retries ||= 0
        Document.transaction(requires_new: true) do
          Document.find_or_create_by!(
            content_id: content_id,
            locale: locale
          ).lock!
        end
      rescue ActiveRecord::RecordNotUnique
        # This should never need more than 1 retry as the scenario this error
        # would occur is: inbetween rails find_or_create SELECT & INSERT
        # queries a concurrent request ran an INSERT. Thus on retry the
        # SELECT would succeed.
        # So if this actually throws an exception here we probably have a
        # weird underlying problem.
        retry if (retries += 1) == 1
      end
    end
  end
end
