class Presenters::RedirectPresenter
  def initialize(base_path:, content_id:, publishing_app:, redirects:, locale:, public_updated_at: nil, first_published_at: nil)
    @base_path = base_path
    @content_id = content_id
    @publishing_app = publishing_app
    @public_updated_at = public_updated_at
    @redirects = redirects
    @locale = locale
    @first_published_at = first_published_at
  end

  def self.from_unpublished_edition(edition)
    new(
      base_path: edition.base_path,
      content_id: edition.content_id,
      publishing_app: edition.publishing_app,
      public_updated_at: edition.unpublishing.unpublished_at || edition.unpublishing.created_at,
      first_published_at: edition.first_published_at,
      redirects: edition.unpublishing.redirects,
      locale: edition.locale,
    )
  end

  def self.from_published_edition(edition)
    new(
      base_path: edition.base_path,
      content_id: edition.content_id,
      publishing_app: edition.publishing_app,
      public_updated_at: edition.public_updated_at,
      first_published_at: edition.first_published_at,
      redirects: edition.redirects,
      locale: edition.locale,
    )
  end

  def for_content_store(payload_version)
    present.merge(payload_version:)
  end

  def for_message_queue(payload_version)
    present.merge(
      content_id:,
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      payload_version:,
    )
  end

  def for_redirect_helper(content_id)
    present.merge(content_id:, update_type: "major")
  end

private

  attr_reader :base_path,
              :publishing_app,
              :public_updated_at,
              :first_published_at,
              :redirects,
              :content_id,
              :locale

  def present
    attributes = {
      document_type: "redirect",
      schema_name: "redirect",
      base_path:,
      locale:,
      publishing_app:,
      redirects:,
    }
    attributes.merge(formatted_dates)
  end

  def formatted_dates
    {
      public_updated_at:,
      first_published_at:,
    }.compact
     .transform_values { |v| v.utc.iso8601 }
  end
end
