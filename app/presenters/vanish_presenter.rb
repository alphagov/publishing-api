class VanishPresenter
  def initialize(base_path:, publishing_app:)
    @base_path = base_path
    @publishing_app = publishing_app
    @content_id = content_id
    @locale = locale
  end

  def self.from_edition(edition)
    new(
      base_path: edition.base_path,
      publishing_app: edition.publishing_app,
    )
  end

  def for_content_store(payload_version)
    present.merge(payload_version: payload_version)
  end

  def for_message_queue
    present.merge(
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
    )
  end

private

  attr_reader :base_path, :publishing_app, :content_id, :locale

  def present
    {
      document_type: "vanish",
      schema_name: "vanish",
      base_path: base_path,
      publishing_app: publishing_app,
    }
  end
end
