namespace :heartbeat_messages do
  desc "Send heartmessages to queue"
  task :send => :environment do
    publisher = PublishingAPI.service(:queue_publisher)

    puts "Sending heartbeat message..."
    publisher.send_heartbeat
    puts "Heartbeat sent."
  end
end
