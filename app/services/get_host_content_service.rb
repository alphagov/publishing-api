class GetHostContentService
  attr_reader :target_content_id

  def initialize(target_content_id)
    self.target_content_id = target_content_id
  end

  def call
    if Document.find_by(content_id: target_content_id).nil?
      message = "Could not find an edition to get embedded content for"
      raise CommandError.new(code: 404, message:)
    end

    Presenters::EmbeddedContentPresenter.present(
      target_content_id,
      host_content,
    )
  end

private

  attr_writer :target_content_id

  def host_content
    @host_content ||= Queries::GetEmbeddedContent.new(target_content_id).call
  end
end
