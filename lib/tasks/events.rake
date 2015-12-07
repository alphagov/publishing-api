namespace :events do
  desc "Exports events from a given timestamp to tmp/events.json"
  task export: :environment do
    timestamp = ENV.fetch("TIMESTAMP")
    datetime = DateTime.parse(timestamp)

    events = Event.where("created_at >= ?", datetime).order(:created_at)
    json_events = events.map { |e| e.as_json.except("id").to_json }

    File.open("tmp/events.json", "w") do |file|
      file.puts json_events
    end
  end

  desc "Imports events from tmp/events.json"
  task import: :environment do
    json_events = File.read("tmp/events.json").split("\n")
    hash_events = json_events.map { |json| JSON.parse(json) }

    hash_events.each do |hash|
      action = hash.fetch("action")
      payload = hash.fetch("payload")
      command = "Commands::#{action}".constantize

      begin
        response = EventLogger.log_command(command, payload) do
          command.call(payload)
        end

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

    puts
  end
end
