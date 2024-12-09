class GetHostContentItemService
  def initialize(target_content_id, host_content_id)
    @target_content_id = target_content_id
    @host_content_id = host_content_id
  end

  def call
    if Document.find_by(content_id: target_content_id).nil?
      message = "Could not find an edition to get host content for"
      raise CommandError.new(code: 404, message:)
    end

    if results.count.zero?
      message = "Could not find host_content_id #{host_content_id} in host content for #{target_content_id}"
      raise CommandError.new(code: 404, message:)
    end

    Presenters::HostContentItemPresenter.present(results[0])
  end

private

  attr_accessor :target_content_id, :order, :page, :per_page, :host_content_id

  def query
    @query ||= Queries::GetHostContent.new(target_content_id, host_content_id:)
  end

  def results
    @results ||= query.call
  end
end
