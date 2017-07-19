class RedirectPresenter
  def initialize(base_path:, publishing_app:, public_updated_at:, redirects:)
    @base_path = base_path
    @publishing_app = publishing_app
    @public_updated_at = public_updated_at
    @redirects = redirects
  end

  def self.from_edition(edition)
    new(
      base_path: edition.base_path,
      publishing_app: edition.publishing_app,
      public_updated_at: edition.unpublishing.created_at,
      redirects: edition.unpublishing.redirects,
    )
  end

  def for_content_store(payload_version)
    present.merge(payload_version: payload_version)
  end

  def for_message_queue
    present.merge(
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id]
    )
  end

  def for_redirect_helper(content_id)
    present.merge(content_id: content_id)
  end

private

  attr_reader :base_path, :publishing_app, :public_updated_at, :redirects,
    :content_id, :locale

  def present
    {
      document_type: "redirect",
      schema_name: "redirect",
      base_path: base_path,
      publishing_app: publishing_app,
      public_updated_at: public_updated_at.iso8601,
      redirects: redirects,
    }
  end
end
