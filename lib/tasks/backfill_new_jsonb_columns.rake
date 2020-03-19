desc "Backfill new temp jsonb columns with data from original json colums"
task backfill_new_jsonb_columns: :environment do
  AccessLimit.find_each.with_index do |access_limit, index|
    access_limit.update(
      temp_users: access_limit.users,
      temp_organisations: access_limit.organisations,
    )
    puts "Updated #{(index + 1)} temp_users and temp_organisations"
  end

  Edition.find_each.with_index do |edition, index|
    edition.update(
      temp_details: edition.details,
      temp_routes: edition.routes,
      temp_redirects: edition.redirects,
    )
    puts "Updated #{(index + 1)} temp_details, temp_routes and temp_redirects"
  end

  Event.find_each.with_index do |event, index|
    event.update(temp_payload: event.payload)
    puts "Updated #{(index + 1)} temp_payload"
  end

  ExpandedLinks.find_each.with_index do |expanded_links, index|
    expanded_links.update(temp_expanded_links: expanded_links.expanded_links)
    puts "Updated #{(index + 1)} temp_expanded_links"
  end

  Unpublishing.find_each.with_index do |unpublishing, index|
    unpublishing.update(temp_redirects: unpublishing.redirects)
    puts "Updated #{(index + 1)} temp_redirects"
  end
end
