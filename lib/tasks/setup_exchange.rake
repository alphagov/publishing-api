task setup_exchange: :environment do
  config = YAML.load_file(Rails.root.join("config/rabbitmq.yml"))[Rails.env].symbolize_keys

  bunny = Bunny.new(ENV["RABBITMQ_URL"])
  channel = bunny.start.create_channel
  Bunny::Exchange.new(channel, :topic, config[:exchange])
end
