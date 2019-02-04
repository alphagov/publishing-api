class DataHygiene::DocumentStatusChecker
  def initialize(document)
    @document = document
  end

  def content_store?
    routes.each do |route|
      content_item = GdsApi.content_store.content_item(route[:path])
      updated_at = DateTime.parse(content_item["updated_at"])
      return false unless updated_at >= edition.published_at # content-store must be later due to latency
    end

    true
  rescue GdsApi::ContentStore::ItemNotFound
    false
  end

  def router?
    routes.each do |route|
      route = GdsApi.router.get_route(route[:path])
      return false unless route["backend_id"] == edition.rendering_app
    end

    true
  rescue GdsApi::HTTPNotFound
    false
  end

private

  attr_reader :document

  def edition
    @edition ||= document.live
  end

  def routes
    @routes ||= edition.routes
  end
end
