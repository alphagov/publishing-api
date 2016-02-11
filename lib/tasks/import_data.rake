require "tasks/import_path_reservations"

desc "Reports missing path reservations from the provided JSON file (one doc per line)"
task :report_path_reservations, [:json_file_path] => :environment do |_, args|
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
      stdout: STDOUT,
      create_reservations: true
    ).import_all
  end
end

desc "Exports path reservations as JSON"
task :export_path_reservations, [:export_file_path] => :environment do |_, args|
  file_path = args[:export_file_path]

  File.open(file_path, 'w') do |file|
    PathReservation.find_each do |path_reservation|
      file.puts path_reservation.attributes.except("id").to_json
    end
  end
end
