schema_name = ARGV
batch_size = 50_000

unfiltered_base_paths = File
  .readlines("script/unfiltered_base_paths")
  .map(&:chomp)
batch_count = (unfiltered_base_paths.count.to_f / batch_size).ceil
filtered_base_paths = []

puts "Filtering #{unfiltered_base_paths.count} base paths by schema name in #{batch_count} batch(es) of up to #{batch_size}
Target schema names: #{schema_name.sort.join(', ')}\n\n"

case Rails.application.name
when "publishing-api"
  puts "Filtering with Publishing API

Note: this requires a replicated Publishing API database\n\n"

  def query(unfiltered_base_paths, schema_name)
    Edition
      .live
      .where(
        base_path: unfiltered_base_paths,
        schema_name:,
      )
      .pluck(:base_path)
  end
when "content-store"
  puts "Filtering with Content Store

Note: this requires a replicated Content Store database\n\n"

  def query(unfiltered_base_paths, schema_name) # rubocop:disable Lint/DuplicateMethods
    ContentItem
      .where(
        base_path: unfiltered_base_paths,
        schema_name:,
      )
      .pluck(:base_path)
  end
end

unfiltered_base_paths
  .each_slice(batch_size)
  .with_index do |unfiltered_base_paths_slice, index|
    puts "Processing batch #{index + 1} of #{batch_count}"

    filtered_base_paths += query(unfiltered_base_paths_slice, schema_name)
end

File.open("script/filtered_base_paths", "w") do |file|
  file.write("#{filtered_base_paths.join("\n")}\n")
end

puts "Finished: found #{filtered_base_paths.count} matching base paths"
