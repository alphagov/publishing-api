class GonePresenter
  def initialize(base_path:, content_id:, publishing_app:, alternative_path:, explanation:, locale:)
    @base_path = base_path
    @content_id = content_id
    @publishing_app = publishing_app
    @alternative_path = alternative_path
    @explanation = explanation
    @locale = locale
  end

  def self.from_edition(edition)
    new(
      base_path: edition.base_path,
      content_id: edition.content_id,
      publishing_app: edition.publishing_app,
      alternative_path: edition.unpublishing.alternative_path,
      explanation: edition.unpublishing.explanation,
      locale: edition.locale,
    )
  end

  def for_content_store(payload_version)
    present.merge(payload_version: payload_version)
  end

  def for_message_queue(payload_version)
    present.merge(
      content_id: content_id,
      govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
      payload_version: payload_version,
    )
  end

private

  attr_reader :base_path, :content_id, :publishing_app, :alternative_path, :explanation, :locale

  def present
    {
      document_type: "gone",
      schema_name: "gone",
      base_path: base_path,
      locale: locale,
      publishing_app: publishing_app,
      details: {
        explanation: explanation,
        alternative_path: alternative_path,
      },
      routes: routes,
    }
  end

  def routes
    if base_path
      [
        {
          path: base_path,
          type: "exact",
        },
      ]
    else
      []
    end
  end
end
