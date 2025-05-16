schema_name = ARGV
batch_size = 50_000

unfiltered_base_paths = File
  .readlines("script/diff_graphql/unfiltered_base_paths")
  .map(&:chomp)
batch_count = (unfiltered_base_paths.count.to_f / batch_size).ceil
filtered_base_paths = []

puts "Filtering #{unfiltered_base_paths.count} base paths by schema name in #{batch_count} batch(es) of up to #{batch_size}
Target schema names: #{schema_name.sort.join(', ')}

Note: this requires a replicated Publishing API database\n\n"

unfiltered_base_paths
  .each_slice(batch_size)
  .with_index do |unfiltered_base_paths_slice, index|
  puts "Processing batch #{index + 1} of #{batch_count}"

  filtered_base_paths += Edition
    .live
    .where(
      base_path: unfiltered_base_paths_slice,
      schema_name:,
    )
    .pluck(:base_path)
end

File.open("script/diff_graphql/filtered_base_paths", "w") do |file|
  file.write("#{filtered_base_paths.join("\n")}\n")
end

puts "Finished: found #{filtered_base_paths.count} matching base paths"
