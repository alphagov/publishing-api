desc "Validate that all link sets meet the links schema"
task validate_link_sets: :environment do
  ok_count = 0
  empty_count = 0
  missing_schema = []
  error_count = Hash.new {0}

  LinkSet.pluck(:content_id).each do |content_id|
    links = Queries::GetLinkSet.call(content_id)[:links]

    schema_name = Queries::GetLatest.call(
      Edition.with_document.where("documents.content_id": content_id)
    ).pluck(:schema_name).first

    if schema_name.nil?
      missing_schema.append(content_id)
      next
    end

    validator = SchemaValidator.new(
      payload: {links: links},
      schema_name: schema_name,
      schema_type: :links,
    )

    if links == {}
      empty_count += 1
    elsif validator.valid?
      ok_count += 1
    else
      error_count[schema_name] += 1
      puts "#{content_id} invalid for #{schema_name}: #{validator.errors.first}"
      puts links
      puts ""
    end
  end

  puts "Summary:"
  puts "Empty: #{empty_count}"
  puts "OK: #{ok_count}"
  puts "Invalid: #{error_count}"
end