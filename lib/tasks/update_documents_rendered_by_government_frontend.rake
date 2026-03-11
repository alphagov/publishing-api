desc "Update published editions of document types where rendering app is government-frontend"
task update_published_editions_rendered_by_government_frontend: :environment do
  government_frontend_published_editions = Edition.where(state: "published", rendering_app: "government-frontend")
  government_frontend_published_editions.update_all(rendering_app: "frontend")

  document_ids = government_frontend_published_editions.collect(&:document_id)

  content_ids = Document.where(id: document_ids).pluck(:content_id)
  queue = DownstreamQueue::LOW_QUEUE

  content_ids.uniq.each_slice(1000) do |batch|
    Commands::V2::RepresentDownstream.new.call(batch, queue:)
    sleep 5
  end
end
