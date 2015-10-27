require "tasks/import_data"
require "tasks/import_path_reservations"

desc "Imports all content items from the provided JSON file (one doc per line)"
task :import_content_items, [:json_file_path, :state] => :environment do |_, args|
  file_path = args[:json_file_path]
  state = args[:state]

  usage = "rake import_content_items['tmp/content_items.json','draft']"

  unless file_path && File.exist?(file_path)
    puts "Could not find a file at '#{file_path}'"
    puts "Please provide a path to a file with one JSON document per line"
    puts "e.g. #{usage}"
    exit
  end

  unless ["draft", "live"].include?(state)
    puts "Please specify whether to import as 'draft' or 'live'"
    puts "e.g. #{usage}"
    exit
  end

  line_count = `wc -l #{file_path}`.strip.split(' ').first.to_i

  File.open(file_path, "r") do |file|
    Tasks::ImportData.new(
      file: file,
      total_lines: line_count,
      stdout: STDOUT,
      draft: state == "draft"
    ).import_all
  end
end


desc "Imports all path reservations from the provided JSON file (one doc per line)"
task :import_path_reservations, [:json_file_path] => :environment do |_, args|
  file_path = args[:json_file_path]
  state = args[:state]

  usage = "rake import_url_reservations['tmp/reservations.json']"

  unless file_path && File.exist?(file_path)
    puts "Could not find a file at '#{file_path}'"
    puts "Please provide a path to a file with one JSON document per line"
    puts "e.g. #{usage}"
    exit
  end

  line_count = `wc -l #{file_path}`.strip.split(' ').first.to_i

  File.open(file_path, "r") do |file|
    Tasks::ImportPathReservations.new(
      file: file,
      total_lines: line_count,
      stdout: STDOUT
    ).import_all
  end
end
