namespace :email_reports do
  desc "Given a path, creates a chunk of code that can be pasted into email-alert-api to get subscriber lists that would be alerted by a change to that path"
  task :get_subscriber_list_code, %i[govuk_path] => :environment do |_, _args|
    puts_subscriber_list_query(govuk_path)
  end
end

def puts_subscriber_list_query(govuk_path)
  edition = Edition.live.where(base_path: govuk_path).last
  ds_payload = DownstreamPayload.new(edition, 1, draft: false)
  payload = ds_payload.message_queue_payload

  puts("To use: Copy everything between the start and end block markers, and")
  puts("paste into an email-alert-api console")
  puts("")
  puts("=== START BLOCK ===")
  puts("lists = SubscriberListQuery.new(")
  puts("  content_id: \"#{payload[:content_id]}\",")
  puts("  tags: #{(payload[:tags] || {}).merge(additional_items(payload))},")
  puts("  links: #{(payload[:links] || {}).merge(additional_items(payload).merge(taxon_tree: taxon_tree(payload)))},")
  puts("  document_type: \"#{payload[:document_type]}\",")
  puts("  email_document_supertype:  \"#{payload['email_document_supertype']}\",")
  puts("  government_document_supertype:  \"#{payload['government_document_supertype']}\",")
  puts(").lists")
  puts("=== END BLOCK ===")
end

def additional_items(payload)
  {
    user_journey_document_supertype: payload["user_journey_document_supertype"],
    email_document_supertype: payload["email_document_supertype"],
    government_document_supertype: payload["government_document_supertype"],
    content_purpose_subgroup: payload["content_purpose_subgroup"],
    content_purpose_supergroup: payload["content_purpose_supergroup"],
    content_store_document_type: payload[:document_type],
  }
end

def taxon_tree(payload)
  [payload[:expanded_links][:taxons].first[:content_id]] + get_parent_links(payload[:expanded_links][:taxons].first)
end

def get_parent_links(taxon_struct)
  return [] unless taxon_struct[:links].key?(:parent_taxons)
  return [] unless taxon_struct[:links][:parent_taxons].any?

  tree = []
  taxon_struct[:links][:parent_taxons].each do |parent_taxon|
    tree += [parent_taxon[:content_id]]
    tree += get_parent_links(parent_taxon)
  end

  tree
end
