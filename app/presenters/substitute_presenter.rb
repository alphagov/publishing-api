class Presenters::SubstitutePresenter
  def initialize(base_path:, content_id:, publishing_app:, locale:)
    @base_path = base_path
    @publishing_app = publishing_app
    @content_id = content_id
    @locale = locale
  end

  def self.from_edition(edition)
    new(
      base_path: edition.base_path,
      content_id: edition.content_id,
      locale: edition.locale,
      publishing_app: edition.publishing_app,
    )
  end

  def for_message_queue(payload_version)
    {
      document_type: "vanish",
      schema_name: "vanish",
      base_path: @base_path,
      locale: @locale,
      publishing_app: @publishing_app,
      content_id: @content_id,
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      payload_version:,
    }
  end
end