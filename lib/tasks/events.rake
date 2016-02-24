
namespace :events do
  desc "Exports events from a given timestamp to tmp/events.json"
  task export: :environment do
    timestamp = ENV.fetch("TIMESTAMP")
    datetime = DateTime.parse(timestamp)

    events = Event.where("created_at >= ?", datetime).order(:created_at)

    File.open("tmp/events.json", "w") do |file|
      events.find_each do |event|
        file.puts event.as_json.except("id").to_json
      end
    end
  end

  desc "Imports events from tmp/events.json"
  task import: :environment do
    File.open("tmp/events.json", "r") do |file|
      file.each do |line|
        hash = JSON.parse(line)

        action = hash.fetch("action")
        payload = hash.fetch("payload")

        begin
          command = "Commands::#{action}".constantize
        rescue NameError
          command = "Commands::V2::#{action}".constantize
        end


        begin
          response = command.call(payload.deep_symbolize_keys, downstream: false)

          if response.code == 200
            print "."
          else
            puts
            puts "#{command} #{response.data}"
          end
        rescue => e
          puts
          puts "#{command} raised an error: #{e.message}"
        end
      end
    end
  end

  puts
end
