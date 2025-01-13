desc "Add a document type to the payload of HostContentUpdateJob events"
task add_document_type_to_host_content_update_events: :environment do
  events = Event.where(action: "HostContentUpdateJob")
  content_ids = events.map { |e| e.payload.dig(:source_block, :content_id) }
  editions = Edition.with_document.where(state: "published", documents: { content_id: content_ids })
  document_types = editions.map { |e| [e.document.content_id, e.document_type] }.to_h

  events.each do |event|
    content_id = event.payload.dig(:source_block, :content_id)
    document_type = document_types[content_id]
    next unless content_id && document_type

    event.payload = event.payload.deep_merge({ source_block: { document_type: } })
    event.save!
  end
end
